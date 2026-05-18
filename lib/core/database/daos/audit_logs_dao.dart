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

  Future<void> clearAll() {
    return delete(auditLogsTable).go();
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
