import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/default_permission_matrix.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';

void main() {
  group('pos.hold_sale role resolution', () {
    test('cashier may hold sales and see held sales', () {
      final m = DefaultPermissionMatrix.forRole('cashier');
      expect(m[PermissionKeys.posHoldSale], isTrue);
      expect(m[PermissionKeys.navHeldSales], isTrue);
      expect(
        RolePermissionMatrix.allows('cashier', AppPermission.holdSale),
        isTrue,
      );
    });

    test('branch manager may hold sales', () {
      final m = DefaultPermissionMatrix.forRole('branch_manager');
      expect(m[PermissionKeys.posHoldSale], isTrue);
      expect(m[PermissionKeys.navHeldSales], isTrue);
      expect(
        RolePermissionMatrix.allows('branch_manager', AppPermission.holdSale),
        isTrue,
      );
    });

    test('owner / super admin inherit hold via full matrix', () {
      for (final role in ['owner', 'super_admin', 'business_owner']) {
        final m = DefaultPermissionMatrix.forRole(role);
        expect(m[PermissionKeys.posHoldSale], isTrue, reason: role);
        expect(m[PermissionKeys.navHeldSales], isTrue, reason: role);
      }
    });

    test('inventory staff cannot hold sales', () {
      final m = DefaultPermissionMatrix.forRole('inventory_staff');
      expect(m[PermissionKeys.posHoldSale], isFalse);
      expect(m[PermissionKeys.navHeldSales], isFalse);
      expect(
        RolePermissionMatrix.allows('inventory_staff', AppPermission.holdSale),
        isFalse,
      );
    });

    test('keys are registered in the canonical key set', () {
      expect(PermissionKeys.all, contains(PermissionKeys.posHoldSale));
      expect(PermissionKeys.all, contains(PermissionKeys.navHeldSales));
    });

    test('online and offline matrices agree for both new keys', () {
      // Every role string the offline matrix knows about must also reflect the
      // same hold-sale grant in the AppPermission-based role matrix.
      const expectations = {
        'cashier': true,
        'branch_manager': true,
        'inventory_staff': false,
      };
      expectations.forEach((role, granted) {
        final offline =
            DefaultPermissionMatrix.forRole(role)[PermissionKeys.posHoldSale];
        final online = RolePermissionMatrix.allows(
          role,
          AppPermission.holdSale,
        );
        expect(offline, granted, reason: '$role offline');
        expect(online, granted, reason: '$role online');
      });
    });
  });
}
