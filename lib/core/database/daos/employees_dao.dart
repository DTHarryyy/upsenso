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
    return (select(employeesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns a map of authUserId → fullName for the given Supabase auth UIDs.
  /// Also matches on the legacy [userId] column for employees whose [authUserId]
  /// was never populated (e.g., records created before auth_user_id tracking).
  Future<Map<String, String>> getNamesForAuthUserIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await (select(employeesTable)
          ..where(
            (t) => t.authUserId.isIn(ids) | t.userId.isIn(ids),
          ))
        .get();
    final result = <String, String>{};
    for (final r in rows) {
      final name = r.fullName;
      if (name == null || name.isEmpty) continue;
      // Prefer authUserId as the canonical key; fall back to userId for legacy records.
      if (r.authUserId != null && ids.contains(r.authUserId)) {
        result[r.authUserId!] = name;
      } else if (r.userId != null && ids.contains(r.userId)) {
        result[r.userId!] = name;
      }
    }
    return result;
  }

  // Idempotent local cache write. A background sync pull can race the create
  // flow and cache this row first; a plain insert would then throw a spurious
  // unique-constraint error even though the employee was created fine.
  Future<void> insertEmployee(EmployeesTableCompanion companion) {
    return into(employeesTable).insertOnConflictUpdate(companion);
  }

  Future<void> updateEmployee(String id, EmployeesTableCompanion companion) {
    return (update(employeesTable)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> upsertFromServer(EmployeesTableCompanion companion) {
    return into(employeesTable).insertOnConflictUpdate(companion);
  }

  Future<void> deleteEmployee(String id) async {
    final row = await (select(employeesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
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
    return (select(employeesTable)
          ..where(
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
}
