import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/fraud_flags_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'fraud_flags_dao.g.dart';

@DriftAccessor(tables: [FraudFlagsTable])
class FraudFlagsDao extends DatabaseAccessor<AppDatabase>
    with _$FraudFlagsDaoMixin {
  FraudFlagsDao(super.db);

  /// Live feed for the alerts UI, newest detections first.
  /// [branchId] narrows to one branch (client mirror of the server's
  /// branch-scoped SELECT); business-wide flags (null branch) stay visible
  /// only in the unfiltered owner view.
  Stream<List<FraudFlagRow>> watchByBusiness(
    String businessId, {
    String? branchId,
  }) {
    return (select(fraudFlagsTable)
          ..where((t) {
            var expr = t.businessId.equals(businessId) & t.deletedAt.isNull();
            if (branchId != null) {
              expr = expr & t.branchId.equals(branchId);
            }
            return expr;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.detectedAt)]))
        .watch();
  }

  /// Inserts a newly detected flag unless this incident was already flagged
  /// (same business + dedupeKey) — by any device, any sweep. Returns whether
  /// a row was written. Never updates an existing flag: forensic fields are
  /// immutable and triage state must not be clobbered by a re-sweep.
  Future<bool> insertIfNew(FraudFlagsTableCompanion companion) async {
    final exists = await (select(fraudFlagsTable)
          ..where(
            (t) =>
                t.businessId.equals(companion.businessId.value) &
                t.dedupeKey.equals(companion.dedupeKey.value),
          )
          ..limit(1))
        .getSingleOrNull();
    if (exists != null) return false;
    await into(fraudFlagsTable).insert(companion);
    return true;
  }

  /// Triage: status transition + resolution note. Only these fields ever
  /// change post-insert (the server freeze trigger rejects anything else).
  Future<void> resolve({
    required String id,
    required String status,
    required String resolvedBy,
    String? resolutionNote,
  }) {
    final now = DateTime.now();
    return (update(fraudFlagsTable)..where((t) => t.id.equals(id))).write(
      FraudFlagsTableCompanion(
        status: Value(status),
        resolvedBy: Value(resolvedBy),
        resolutionNote: Value(resolutionNote),
        updatedAt: Value(now),
        clientUpdatedAt: Value(now),
        syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
      ),
    );
  }

  /// One-time cleanup of the 2026-07-03 false-positive flags (see
  /// docs/UPSENSO_FRAUD_FALSE_POSITIVE_FIX_PLAN.md, P0.4). Dismisses `new`
  /// flags of the given rule codes detected before [before], attributing the
  /// dismissal to [resolvedBy] with [note].
  ///
  /// Crucially routes them to [SyncStatus.pendingUpload], NOT pendingUpdate:
  /// these rows never reached the server, so an UPDATE would match nothing
  /// and silently lose the forensic record. As a full insert the dismissed
  /// flag lands server-side with its resolution intact. Returns the count.
  Future<int> bulkDismiss({
    required String businessId,
    required Set<String> ruleCodes,
    required DateTime before,
    required String resolvedBy,
    required String note,
  }) async {
    if (ruleCodes.isEmpty) return 0;
    final now = DateTime.now();
    return (update(fraudFlagsTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.ruleCode.isIn(ruleCodes) &
                t.status.equals('new') &
                t.detectedAt.isSmallerThanValue(before),
          ))
        .write(
      FraudFlagsTableCompanion(
        status: const Value('dismissed'),
        resolvedBy: Value(resolvedBy),
        resolutionNote: Value(note),
        updatedAt: Value(now),
        clientUpdatedAt: Value(now),
        syncStatus: Value(SyncStatus.pendingUpload.toInt()),
      ),
    );
  }

  Future<List<FraudFlagRow>> getPendingSync() {
    return (select(fraudFlagsTable)
          ..where(
            (t) => t.syncStatus.isIn([
              SyncStatus.pendingUpload.toInt(),
              SyncStatus.pendingUpdate.toInt(),
              SyncStatus.failed.toInt(),
            ]),
          )
          ..limit(200))
        .get();
  }

  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) {
    return (update(fraudFlagsTable)..where((t) => t.id.equals(id))).write(
      FraudFlagsTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// A dedupe race with another device: the server already holds this
  /// incident under a different row id. This local duplicate is superseded —
  /// soft-hide it and stop pushing it; the canonical row arrives on pull.
  Future<void> markSuperseded(String id) {
    return (update(fraudFlagsTable)..where((t) => t.id.equals(id))).write(
      FraudFlagsTableCompanion(
        deletedAt: Value(DateTime.now()),
        syncStatus: Value(SyncStatus.synced.toInt()),
        syncError: const Value('superseded by remote dedupe'),
      ),
    );
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(fraudFlagsTable).insertOnConflictUpdate(
      FraudFlagsTableCompanion.insert(
        id: row['id'] as String,
        businessId: row['business_id'] as String,
        branchId: Value(row['branch_id'] as String?),
        ruleCode: row['rule_code'] as String,
        severity: row['severity'] as String,
        status: Value(row['status'] as String? ?? 'new'),
        title: row['title'] as String,
        description: row['description'] as String,
        subjectUserId: Value(row['subject_user_id'] as String?),
        evidence: Value(_jsonText(row['evidence'], fallback: '[]')),
        relatedIds: Value(_jsonText(row['related_ids'], fallback: '[]')),
        resolvedBy: Value(row['resolved_by'] as String?),
        resolutionNote: Value(row['resolution_note'] as String?),
        detectedAt: DateTime.parse(row['detected_at'] as String),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        deletedAt: Value(
          row['deleted_at'] != null
              ? DateTime.parse(row['deleted_at'] as String)
              : null,
        ),
        dedupeKey: row['dedupe_key'] as String,
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
  }

  Future<void> clearAll() {
    return delete(fraudFlagsTable).go();
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = fraudFlagsTable.id.count();
    final query = selectOnly(fraudFlagsTable)
      ..addColumns([countExp])
      ..where(
        fraudFlagsTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }
}

/// evidence/related_ids are jsonb remotely (decoded to Map/List by the
/// client) but stored as JSON text locally.
String _jsonText(Object? value, {required String fallback}) {
  if (value == null) return fallback;
  if (value is String) return value;
  try {
    return jsonEncode(value);
  } catch (_) {
    return fallback;
  }
}
