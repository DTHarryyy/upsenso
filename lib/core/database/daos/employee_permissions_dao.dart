import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/employee_permissions_table.dart';

part 'employee_permissions_dao.g.dart';

@DriftAccessor(tables: [EmployeePermissionsTable])
class EmployeePermissionsDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeePermissionsDaoMixin {
  EmployeePermissionsDao(super.db);

  /// Returns the cached [Map<String, bool>] for [authUserId], or `null` when
  /// no local cache exists yet.
  Future<Map<String, bool>?> getPermissions(String authUserId) async {
    final row = await (select(
      employeePermissionsTable,
    )..where((t) => t.authUserId.equals(authUserId))).getSingleOrNull();

    if (row == null) return null;

    final raw = json.decode(row.permissionsJson) as Map<String, dynamic>;
    return raw.map((k, v) => MapEntry(k, v as bool));
  }

  /// Persists [permissions] for [authUserId].
  ///
  /// Sets [syncedAt] to now when [fromRemote] is true (i.e. the data came
  /// from Supabase), and leaves it null for role-derived seed rows.
  Future<void> savePermissions(
    String authUserId,
    Map<String, bool> permissions, {
    String? employeeId,
    bool fromRemote = false,
  }) async {
    final now = DateTime.now();
    await into(employeePermissionsTable).insertOnConflictUpdate(
      EmployeePermissionsTableCompanion(
        authUserId: Value(authUserId),
        employeeId: Value(employeeId),
        permissionsJson: Value(json.encode(permissions)),
        syncedAt: fromRemote ? Value(now) : const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  /// Removes the cached permissions row for [authUserId].
  Future<void> clearPermissions(String authUserId) async {
    await (delete(
      employeePermissionsTable,
    )..where((t) => t.authUserId.equals(authUserId))).go();
  }

  /// Returns the [syncedAt] timestamp for [authUserId], or `null` when the row
  /// does not exist or was never synced from Supabase.
  Future<DateTime?> lastSyncedAt(String authUserId) async {
    final row = await (select(
      employeePermissionsTable,
    )..where((t) => t.authUserId.equals(authUserId))).getSingleOrNull();
    return row?.syncedAt;
  }
}
