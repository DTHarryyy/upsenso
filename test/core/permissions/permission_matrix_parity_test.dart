import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/default_permission_matrix.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';

/// Guards against the online (enum-based) and offline (string-keyed) RBAC
/// matrices drifting apart. CLAUDE.md requires them to stay in sync — an
/// offline-seeded employee must resolve the same grants as one loaded from
/// Supabase. Only keys with an AppPermission projection are comparable here;
/// nav.*/dashboard.* visibility keys have no enum equivalent by design.
void main() {
  const roles = [
    RolePermissionMatrix.branchManager,
    RolePermissionMatrix.cashier,
    RolePermissionMatrix.inventoryStaff,
  ];

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

  group('DefaultPermissionMatrix mirrors RolePermissionMatrix', () {
    for (final role in roles) {
      test('matches for role "$role"', () {
        final enumMap = projectEnum(role);
        final offlineMap = DefaultPermissionMatrix.forRole(role);
        for (final key in mappedKeys) {
          expect(
            offlineMap[key] ?? false,
            enumMap[key] ?? false,
            reason:
                'Permission key "$key" disagrees between the offline and '
                'enum matrices for role "$role". Keep both in sync.',
          );
        }
      });
    }
  });

  test('Business Owner has every permission in both matrices', () {
    for (final adminKey in [
      RolePermissionMatrix.businessOwner,
      RolePermissionMatrix.owner,
      RolePermissionMatrix.superAdmin,
    ]) {
      expect(
        RolePermissionMatrix.permissionsFor(adminKey).length,
        AppPermission.values.length,
      );
      final offline = DefaultPermissionMatrix.forRole(adminKey);
      expect(offline.values.every((v) => v), isTrue);
    }
  });
}
