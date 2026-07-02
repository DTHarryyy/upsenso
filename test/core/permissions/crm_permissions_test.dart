import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/default_permission_matrix.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';

/// Locks the CRM permission matrix so a future edit to either
/// [RolePermissionMatrix] (online, enum-keyed) or [DefaultPermissionMatrix]
/// (offline fallback, string-keyed) can't silently drift the two apart, and
/// can't silently regrant/deny CRM access for a role.
///
/// Expected shape (see CLAUDE.md permission model):
///   Owner/Super Admin — crm.view + crm.manage + nav.customers (all true)
///   Branch Manager    — crm.view + crm.manage + nav.customers (all true)
///   Cashier           — crm.view only (manage/nav false) — can attach an
///                        existing customer at checkout, can't quick-add
///   Inventory Staff   — none
void main() {
  group('CRM permissions — DefaultPermissionMatrix (offline fallback)', () {
    test('owner gets full CRM access', () {
      final m = DefaultPermissionMatrix.forRole('owner');
      expect(m[PermissionKeys.crmView], isTrue);
      expect(m[PermissionKeys.crmManage], isTrue);
      expect(m[PermissionKeys.navCustomers], isTrue);
    });

    test('branch manager gets full CRM access', () {
      final m = DefaultPermissionMatrix.forRole('branch_manager');
      expect(m[PermissionKeys.crmView], isTrue);
      expect(m[PermissionKeys.crmManage], isTrue);
      expect(m[PermissionKeys.navCustomers], isTrue);
    });

    test('cashier gets view only — no manage, no nav', () {
      final m = DefaultPermissionMatrix.forRole('cashier');
      expect(m[PermissionKeys.crmView], isTrue);
      expect(m[PermissionKeys.crmManage], isFalse);
      expect(m[PermissionKeys.navCustomers], isFalse);
    });

    test('inventory staff gets no CRM access', () {
      final m = DefaultPermissionMatrix.forRole('inventory_staff');
      expect(m[PermissionKeys.crmView], isFalse);
      expect(m[PermissionKeys.crmManage], isFalse);
      expect(m[PermissionKeys.navCustomers], isFalse);
    });
  });

  group('CRM permissions — RolePermissionMatrix (online)', () {
    test('owner gets full CRM access', () {
      const role = RolePermissionMatrix.owner;
      expect(RolePermissionMatrix.allows(role, AppPermission.viewCustomers), isTrue);
      expect(RolePermissionMatrix.allows(role, AppPermission.manageCustomers), isTrue);
      expect(
        RolePermissionMatrix.canAccessFeature(role, AppFeature.customerDirectory),
        isTrue,
      );
    });

    test('branch manager gets full CRM access', () {
      const role = RolePermissionMatrix.branchManager;
      expect(RolePermissionMatrix.allows(role, AppPermission.viewCustomers), isTrue);
      expect(RolePermissionMatrix.allows(role, AppPermission.manageCustomers), isTrue);
      expect(
        RolePermissionMatrix.canAccessFeature(role, AppFeature.customerDirectory),
        isTrue,
      );
    });

    test('cashier gets view only — no manage, no directory feature', () {
      const role = RolePermissionMatrix.cashier;
      expect(RolePermissionMatrix.allows(role, AppPermission.viewCustomers), isTrue);
      expect(RolePermissionMatrix.allows(role, AppPermission.manageCustomers), isFalse);
      expect(
        RolePermissionMatrix.canAccessFeature(role, AppFeature.customerDirectory),
        isFalse,
      );
    });

    test('inventory staff gets no CRM access', () {
      const role = RolePermissionMatrix.inventoryStaff;
      expect(RolePermissionMatrix.allows(role, AppPermission.viewCustomers), isFalse);
      expect(RolePermissionMatrix.allows(role, AppPermission.manageCustomers), isFalse);
      expect(
        RolePermissionMatrix.canAccessFeature(role, AppFeature.customerDirectory),
        isFalse,
      );
    });
  });

  group('CRM permissions — online/offline matrices stay in sync', () {
    // (onlineRoleKey, offlineRoleKey) pairs — the two matrices normalise role
    // names slightly differently (RolePermissionMatrix.branchManager ==
    // 'branch_manager' == DefaultPermissionMatrix's switch case).
    const roles = [
      (RolePermissionMatrix.owner, 'owner'),
      (RolePermissionMatrix.branchManager, 'branch_manager'),
      (RolePermissionMatrix.cashier, 'cashier'),
      (RolePermissionMatrix.inventoryStaff, 'inventory_staff'),
    ];

    for (final (onlineRole, offlineRole) in roles) {
      test('"$offlineRole" resolves identically online vs offline', () {
        final offline = DefaultPermissionMatrix.forRole(offlineRole);

        expect(
          RolePermissionMatrix.allows(onlineRole, AppPermission.viewCustomers),
          offline[PermissionKeys.crmView],
          reason: 'crm.view mismatch for $offlineRole',
        );
        expect(
          RolePermissionMatrix.allows(onlineRole, AppPermission.manageCustomers),
          offline[PermissionKeys.crmManage],
          reason: 'crm.manage mismatch for $offlineRole',
        );
        expect(
          RolePermissionMatrix.canAccessFeature(
            onlineRole,
            AppFeature.customerDirectory,
          ),
          offline[PermissionKeys.navCustomers],
          reason: 'nav.customers / customerDirectory feature mismatch for $offlineRole',
        );
      });
    }
  });
}
