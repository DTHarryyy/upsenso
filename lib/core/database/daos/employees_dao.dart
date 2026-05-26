import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/employees_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'employees_dao.g.dart';

@DriftAccessor(tables: [EmployeesTable])
class EmployeesDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeesDaoMixin {
  EmployeesDao(super.db);

  Stream<List<EmployeeRow>> watchByBusinessId(String businessId) {
    return (select(employeesTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.syncStatus.isNotIn([SyncStatus.pendingDelete.toInt()]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .watch();
  }

  Future<List<EmployeeRow>> getByBusinessId(String businessId) {
    return (select(employeesTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.syncStatus.isNotIn([SyncStatus.pendingDelete.toInt()]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .get();
  }

  Future<EmployeeRow?> getById(String id) {
    return (select(
      employeesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Returns a map of authUserId → fullName for the given auth user IDs.
  Future<Map<String, String>> getNamesForAuthUserIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await (select(
      employeesTable,
    )..where((t) => t.authUserId.isIn(ids))).get();
    return {
      for (final r in rows)
        if (r.authUserId != null) r.authUserId!: r.fullName,
    };
  }

  Future<void> insertEmployee(EmployeesTableCompanion companion) {
    return into(employeesTable).insert(companion);
  }

  Future<void> updateEmployee(String id, EmployeesTableCompanion companion) {
    return (update(
      employeesTable,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  Future<void> upsertFromServer(EmployeesTableCompanion companion) {
    return into(employeesTable).insertOnConflictUpdate(companion);
  }

  Future<void> deleteEmployee(String id) async {
    final row = await (select(
      employeesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    if (row.syncStatus == SyncStatus.pendingUpload.toInt()) {
      await (delete(employeesTable)..where((t) => t.id.equals(id))).go();
    } else {
      await (update(employeesTable)..where((t) => t.id.equals(id))).write(
        EmployeesTableCompanion(
          syncStatus: Value(SyncStatus.pendingDelete.toInt()),
        ),
      );
    }
  }

  Future<void> clearAll() {
    return delete(employeesTable).go();
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = employeesTable.id.count();
    final query = selectOnly(employeesTable)
      ..addColumns([countExp])
      ..where(
        employeesTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.pendingDelete.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<EmployeeRow>> getPendingSync() {
    return (select(employeesTable)..where(
          (t) => t.syncStatus.isIn([
            SyncStatus.pendingUpload.toInt(),
            SyncStatus.pendingUpdate.toInt(),
            SyncStatus.pendingDelete.toInt(),
            SyncStatus.failed.toInt(),
          ]),
        ))
        .get();
  }

  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) {
    return (update(employeesTable)..where((t) => t.id.equals(id))).write(
      EmployeesTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(employeesTable)..where((t) => t.id.equals(id))).go();
  }

  /// Returns the first active employee in [businessId] whose email matches
  /// [email] (case-insensitive), excluding the employee with [excludeId] when
  /// editing an existing record.
  Future<EmployeeRow?> findByEmail(
    String businessId,
    String email, {
    String? excludeId,
  }) async {
    final rows =
        await (select(employeesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.syncStatus.isNotIn([SyncStatus.pendingDelete.toInt()]),
            ))
            .get();
    return rows.where((r) {
      if (r.email.toLowerCase() != email.toLowerCase()) return false;
      if (excludeId != null && r.id == excludeId) return false;
      return true;
    }).firstOrNull;
  }

  /// Returns the first active employee in [businessId] whose phone matches
  /// [phone] exactly, excluding the employee with [excludeId] when editing.
  Future<EmployeeRow?> findByPhone(
    String businessId,
    String phone, {
    String? excludeId,
  }) async {
    final rows =
        await (select(employeesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.syncStatus.isNotIn([SyncStatus.pendingDelete.toInt()]) &
                  t.phone.isNotNull(),
            ))
            .get();
    return rows.where((r) {
      if (r.phone != phone) return false;
      if (excludeId != null && r.id == excludeId) return false;
      return true;
    }).firstOrNull;
  }
}
