// One-off diagnostic: diff the enum-based RolePermissionMatrix against the
// string-keyed DefaultPermissionMatrix for every key that has an
// AppPermission projection. Run with: dart run tool/diff_matrices.dart
import 'package:flutter/foundation.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/default_permission_matrix.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';

void main() {
  const roles = ['branch_manager', 'cashier', 'inventory_staff'];

  // Build key -> true if ANY AppPermission mapping to that key is granted.
  Map<String, bool> projectEnum(String roleKey) {
    final granted = RolePermissionMatrix.permissionsFor(roleKey);
    final result = <String, bool>{};
    for (final p in AppPermission.values) {
      final key = p.permissionKey;
      result[key] = (result[key] ?? false) || granted.contains(p);
    }
    return result;
  }

  final mappedKeys = AppPermission.values.map((p) => p.permissionKey).toSet();
  debugPrint('Keys with an AppPermission projection: ${mappedKeys.length}');
  debugPrint(
    'PermissionKeys.all total: ${PermissionKeys.all.length}, '
    'unmapped (nav/dashboard/etc): '
    '${PermissionKeys.all.where((k) => !mappedKeys.contains(k)).length}',
  );
  debugPrint('');

  for (final role in roles) {
    final enumMap = projectEnum(role);
    final offlineMap = DefaultPermissionMatrix.forRole(role);
    debugPrint('=== $role ===');
    for (final key in mappedKeys.toList()..sort()) {
      final enumVal = enumMap[key] ?? false;
      final offlineVal = offlineMap[key] ?? false;
      if (enumVal != offlineVal) {}
    }
    debugPrint('');
  }
}
