import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/audit_logs_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'audit_logs_dao.g.dart';

@DriftAccessor(tables: [AuditLogsTable])
class AuditLogsDao extends DatabaseAccessor<AppDatabase>
    with _$AuditLogsDaoMixin {
  AuditLogsDao(super.db);

  Future<void> insert(AuditLogsTableCompanion companion) {
    return into(auditLogsTable).insert(companion);
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

  Future<List<AuditLogRow>> getPendingSync() {
    return (select(auditLogsTable)
          ..where(
            (t) => t.syncStatus.isIn([
              SyncStatus.pendingUpload.toInt(),
              SyncStatus.failed.toInt(),
            ]),
          )
          ..limit(500))
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
    final description = row['description'] as String? ??
        '${row['action']} on ${row['entity_type']}';
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
        // metadata is jsonb remotely — the client decodes it to a Map, but
        // the local column stores the JSON-encoded text (see AuditLogRow).
        metadata: Value(jsonEncode(row['metadata'] ?? <String, dynamic>{})),
        deviceId: Value(row['device_id'] as String? ?? 'unknown'),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
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
