import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos/core/audit/audit_hash.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/audit_logs_table.dart';
import 'package:pos/core/device/chain_write_lock.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'audit_logs_dao.g.dart';

@DriftAccessor(tables: [AuditLogsTable])
class AuditLogsDao extends DatabaseAccessor<AppDatabase>
    with _$AuditLogsDaoMixin {
  AuditLogsDao(super.db);

  Future<void> insert(AuditLogsTableCompanion companion) {
    return into(auditLogsTable).insert(companion);
  }

  /// Every locally retained chained row for a business, ordered so the
  /// verifier can walk each device chain in seq order. Bounded by the 90-day
  /// local prune window; the pre-chain NULL segment is excluded by definition.
  Future<List<AuditLogRow>> getChainedRows(String businessId) {
    return (select(auditLogsTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.seq.isNotNull() &
                t.deviceUid.isNotNull(),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.deviceUid),
            (t) => OrderingTerm.asc(t.seq),
          ]))
        .get();
  }

  /// Unsynced (pending/failed) chained rows for one device, oldest-first —
  /// the input to conflict self-heal (re-chaining a restarted tail past the
  /// server head).
  Future<List<AuditLogRow>> getUnsyncedByDevice(
    String businessId,
    String deviceUid,
  ) {
    return (select(auditLogsTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.deviceUid.equals(deviceUid) &
                t.seq.isNotNull() &
                t.syncStatus.isIn([
                  SyncStatus.pendingUpload.toInt(),
                  SyncStatus.failed.toInt(),
                ]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
  }

  /// Rewrites a row's chain fields during self-heal and re-queues it for push.
  /// [metadata]/[hashVersion] ride along when the reconcile pass stamps the
  /// `_rechained` marker (the row is re-hashed anyway, so the chain stays
  /// valid and TIME_REVERSAL can tell a transplanted tail from a clock roll).
  Future<void> rewriteChainRow({
    required String id,
    required int seq,
    required String prevHash,
    required String entryHash,
    String? metadata,
    int? hashVersion,
  }) {
    return (update(auditLogsTable)..where((t) => t.id.equals(id))).write(
      AuditLogsTableCompanion(
        seq: Value(seq),
        prevHash: Value(prevHash),
        entryHash: Value(entryHash),
        metadata: metadata != null ? Value(metadata) : const Value.absent(),
        hashVersion:
            hashVersion != null ? Value(hashVersion) : const Value.absent(),
        syncStatus: Value(SyncStatus.pendingUpload.toInt()),
        syncError: const Value(null),
      ),
    );
  }

  /// Newest chained row for one device chain (highest seq), or null when the
  /// chain has no local rows yet.
  Future<AuditLogRow?> getChainHead(String businessId, String deviceUid) {
    return (select(auditLogsTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.deviceUid.equals(deviceUid) &
                t.seq.isNotNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.seq)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Allocates the next seq for (businessId, deviceUid) and inserts in ONE
  /// transaction, so two concurrent log() calls can't double-allocate.
  /// Returns the allocated seq (feeds the storage-eviction sentinel).
  ///
  /// [resumeBase] seeds the chain when the local DB is empty but the server
  /// already has history for this device (reinstall with a surviving uid) —
  /// used only if the in-transaction head check still finds nothing.
  /// [also] runs inside the SAME transaction after the insert — the outbox
  /// drain uses it to delete the staged row atomically with the chained
  /// write, so an entry can neither vanish nor double-log across a crash.
  Future<int> insertChained({
    required String businessId,
    required String deviceUid,
    ({int seq, String hash})? resumeBase,
    required AuditLogsTableCompanion Function(int seq, String prevHash)
        buildRow,
    Future<void> Function()? also,
  }) {
    // Cross-tab guard on web (no-op on native): two tabs sharing this
    // device_uid must not allocate the same seq. The DB transaction already
    // makes the head-read + insert atomic within ONE instance; the lock
    // extends that mutual exclusion across instances.
    return runWithChainLock('audit-chain:$businessId:$deviceUid', () {
      return transaction(() async {
        final head = await getChainHead(businessId, deviceUid);
        final int seq;
        final String prevHash;
        if (head != null) {
          seq = head.seq! + 1;
          // A seq-bearing row always has a hash; genesis fallback only guards
          // against a half-written row, and the verifier reports it either way.
          prevHash = head.entryHash ?? kAuditGenesisHash;
        } else if (resumeBase != null) {
          seq = resumeBase.seq + 1;
          prevHash = resumeBase.hash;
        } else {
          seq = 1;
          prevHash = kAuditGenesisHash;
        }
        await into(auditLogsTable).insert(buildRow(seq, prevHash));
        if (also != null) await also();
        return seq;
      });
    });
  }

  Future<List<AuditLogRow>> getByBusiness(
    String businessId, {
    String? branchId,
    String? userId,
    String? actionType,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) {
    return (select(auditLogsTable)
          ..where((t) {
            Expression<bool> expr = t.businessId.equals(businessId);
            if (branchId != null) expr = expr & t.branchId.equals(branchId);
            if (userId != null) expr = expr & t.userId.equals(userId);
            if (actionType != null) {
              expr = expr & t.actionType.equals(actionType);
            }
            if (from != null) {
              expr = expr & t.createdAt.isBiggerOrEqualValue(from);
            }
            if (to != null) {
              expr = expr & t.createdAt.isSmallerOrEqualValue(to);
            }
            return expr;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<AuditLogRow>> watchByBusiness(
    String businessId, {
    String? branchId,
    String? userId,
    String? actionType,
    int limit = 200,
  }) {
    return (select(auditLogsTable)
          ..where((t) {
            Expression<bool> expr = t.businessId.equals(businessId);
            if (branchId != null) expr = expr & t.branchId.equals(branchId);
            if (userId != null) expr = expr & t.userId.equals(userId);
            if (actionType != null) {
              expr = expr & t.actionType.equals(actionType);
            }
            return expr;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  /// Ordered (device_uid, seq) so chains push oldest-first: an unsorted push
  /// can land seq N+1 before N, and a mid-cycle failure then leaves a server
  /// hole that other devices' verifiers read as a seqGap. Paginated ([limit]
  /// per page) so a long offline backlog drains fully across pages in one
  /// cycle instead of being capped at a single 500-row window.
  Future<List<AuditLogRow>> getPendingSync({int limit = 500}) {
    return (select(auditLogsTable)
          ..where(
            (t) => t.syncStatus.isIn([
              SyncStatus.pendingUpload.toInt(),
              SyncStatus.failed.toInt(),
            ]),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.deviceUid),
            (t) => OrderingTerm.asc(t.seq),
          ])
          ..limit(limit))
        .get();
  }

  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) {
    return (update(auditLogsTable)..where((t) => t.id.equals(id))).write(
      AuditLogsTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// Upsert a row pulled from Supabase — mirrors [StockLedgerDao.upsertFromServer].
  /// Audit rows are immutable once created, so a conflict on [id] only ever
  /// means "this device already has this exact row" (e.g. it's the row's own
  /// origin device, or a previous pull already landed it); overwriting with
  /// identical remote content and marking it synced is always safe.
  ///
  /// Some rows are not written by [AuditLogService] at all — trg_user_perm_audit
  /// / trg_branch_perm_audit / trg_module_audit insert directly via
  /// log_permission_change() on every change to user_permissions,
  /// branch_permissions, and business_modules, using TG_OP as `action` instead
  /// of `action_type`, and never set `description`. Both are non-nullable
  /// locally, so they fall back to AuditLogActionType.permissionTableChanged's
  /// raw string value ('PERMISSION_TABLE_CHANGED') instead of a raw cast — kept
  /// as a literal here, not an import, since core/ must not depend on
  /// features/ (the domain enum is the single source of truth for the string).
  Future<void> upsertFromServer(Map<String, dynamic> row) {
    final actionType =
        row['action_type'] as String? ?? 'PERMISSION_TABLE_CHANGED';
    // Trigger-written permission rows now carry a description; `action` (the
    // legacy column) was dropped in the Stage 2a convergence.
    final description = row['description'] as String? ?? 'Permission change';
    return into(auditLogsTable).insertOnConflictUpdate(
      AuditLogsTableCompanion.insert(
        id: row['id'] as String,
        businessId: row['business_id'] as String,
        branchId: row['branch_id'] as String? ?? '',
        userId: row['user_id'] as String? ?? '',
        actionType: actionType,
        entityType: row['entity_type'] as String,
        entityId: Value(row['entity_id'] as String?),
        description: description,
        // metadata is jsonb remotely — normalized to canonical JSON text for
        // the local column (see _metadataText: a Map is encoded once; a legacy
        // jsonb *string scalar* already IS the JSON text and must NOT be
        // encoded again, or it double-encodes and both display + hash
        // verification break).
        metadata: Value(_metadataText(row['metadata'])),
        deviceId: Value(row['device_id'] as String? ?? 'unknown'),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        // Chain fields ride along so the owner device can verify other
        // devices' chains from its pulled mirror. Server column names differ:
        // previous_hash/hash predate this feature and were adopted as-is.
        seq: Value((row['seq'] as num?)?.toInt()),
        prevHash: Value(row['previous_hash'] as String?),
        entryHash: Value(row['hash'] as String?),
        deviceUid: Value(row['device_uid'] as String?),
        hashVersion: Value((row['hash_version'] as num?)?.toInt()),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
  }

  /// Canonical local JSON text for a metadata value pulled from Supabase.
  /// A well-formed row decodes to a Map (encode once); legacy rows stored as
  /// jsonb string scalars arrive as a String that already IS the JSON text
  /// (keep as-is — re-encoding would double it).
  static String _metadataText(Object? raw) {
    if (raw == null) return '{}';
    if (raw is String) return raw.isEmpty ? '{}' : raw;
    return jsonEncode(raw);
  }

  Future<void> clearAll() {
    return delete(auditLogsTable).go();
  }

  /// Deletes local rows older than [cutoff] — keeps the on-device mirror
  /// bounded to a rolling window (see auditLogLocalWindowDays) now that the
  /// server retains full history forever. Only ever deletes rows already
  /// confirmed [SyncStatus.synced] — a pending or failed row is never
  /// deleted regardless of age, since the server may not have it yet and
  /// this would be the only copy.
  Future<int> pruneOlderThan(DateTime cutoff) {
    return (delete(auditLogsTable)..where(
          (t) =>
              t.createdAt.isSmallerThanValue(cutoff) &
              t.syncStatus.equals(SyncStatus.synced.toInt()),
        ))
        .go();
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = auditLogsTable.id.count();
    final query = selectOnly(auditLogsTable)
      ..addColumns([countExp])
      ..where(
        auditLogsTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }
}
