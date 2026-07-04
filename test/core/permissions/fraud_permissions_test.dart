import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/default_permission_matrix.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';

/// Locks the M1 fraud/audit-chain permission matrix so a future edit to
/// either [RolePermissionMatrix] (online) or [DefaultPermissionMatrix]
/// (offline fallback) can't silently drift the two apart. These values must
/// also match the server seeds in 20260703000002 / 20260703000003.
///
/// Expected shape (locked user decision, 2026-07-03):
///   Owner/Super Admin — fraud.view + fraud.resolve + nav.fraud +
///                       audit_logs.verify (all true)
///   Branch Manager    — fraud.view + fraud.resolve + nav.fraud;
///                       audit_logs.verify FALSE (owner-only, like
///                       audit_logs.view — grantable via override)
///   Cashier           — none
///   Inventory Staff   — none
void main() {
  group('Fraud permissions — DefaultPermissionMatrix (offline fallback)', () {
    test('owner gets fraud triage + chain verification', () {
      final m = DefaultPermissionMatrix.forRole('owner');
      expect(m[PermissionKeys.fraudView], isTrue);
      expect(m[PermissionKeys.fraudResolve], isTrue);
      expect(m[PermissionKeys.navFraud], isTrue);
      expect(m[PermissionKeys.auditLogsVerify], isTrue);
    });

    test('branch manager triages fraud but does not verify the chain', () {
      final m = DefaultPermissionMatrix.forRole('branch_manager');
      expect(m[PermissionKeys.fraudView], isTrue);
      expect(m[PermissionKeys.fraudResolve], isTrue);
      expect(m[PermissionKeys.navFraud], isTrue);
      expect(m[PermissionKeys.auditLogsVerify], isFalse);
    });

    test('cashier gets no fraud access', () {
      final m = DefaultPermissionMatrix.forRole('cashier');
      expect(m[PermissionKeys.fraudView], isFalse);
      expect(m[PermissionKeys.fraudResolve], isFalse);
      expect(m[PermissionKeys.navFraud], isFalse);
      expect(m[PermissionKeys.auditLogsVerify], isFalse);
    });

    test('inventory staff gets no fraud access', () {
      final m = DefaultPermissionMatrix.forRole('inventory_staff');
      expect(m[PermissionKeys.fraudView], isFalse);
      expect(m[PermissionKeys.fraudResolve], isFalse);
      expect(m[PermissionKeys.navFraud], isFalse);
      expect(m[PermissionKeys.auditLogsVerify], isFalse);
    });
  });

  group('Fraud permissions — RolePermissionMatrix (online)', () {
    test('owner gets fraud triage + feature + chain verification', () {
      const role = RolePermissionMatrix.owner;
      expect(
        RolePermissionMatrix.allows(role, AppPermission.viewFraudAlerts),
        isTrue,
      );
      expect(
        RolePermissionMatrix.allows(role, AppPermission.resolveFraudAlerts),
        isTrue,
      );
      expect(
        RolePermissionMatrix.allows(role, AppPermission.verifyAuditChain),
        isTrue,
      );
      expect(
        RolePermissionMatrix.canAccessFeature(role, AppFeature.fraudAlerts),
        isTrue,
      );
    });

    test('branch manager triages but does not verify the chain', () {
      const role = RolePermissionMatrix.branchManager;
      expect(
        RolePermissionMatrix.allows(role, AppPermission.viewFraudAlerts),
        isTrue,
      );
      expect(
        RolePermissionMatrix.allows(role, AppPermission.resolveFraudAlerts),
        isTrue,
      );
      expect(
        RolePermissionMatrix.allows(role, AppPermission.verifyAuditChain),
        isFalse,
      );
      expect(
        RolePermissionMatrix.canAccessFeature(role, AppFeature.fraudAlerts),
        isTrue,
      );
    });

    test('cashier and inventory staff get nothing', () {
      for (final role in [
        RolePermissionMatrix.cashier,
        RolePermissionMatrix.inventoryStaff,
      ]) {
        expect(
          RolePermissionMatrix.allows(role, AppPermission.viewFraudAlerts),
          isFalse,
        );
        expect(
          RolePermissionMatrix.allows(role, AppPermission.resolveFraudAlerts),
          isFalse,
        );
        expect(
          RolePermissionMatrix.allows(role, AppPermission.verifyAuditChain),
          isFalse,
        );
        expect(
          RolePermissionMatrix.canAccessFeature(role, AppFeature.fraudAlerts),
          isFalse,
        );
      }
    });
  });

  group('online and offline matrices stay in sync', () {
    const pairs = {
      'branch_manager': RolePermissionMatrix.branchManager,
      'cashier': RolePermissionMatrix.cashier,
      'inventory_staff': RolePermissionMatrix.inventoryStaff,
    };

    test('fraud + audit-verify keys agree for every role', () {
      for (final entry in pairs.entries) {
        final offline = DefaultPermissionMatrix.forRole(entry.key);
        expect(
          offline[PermissionKeys.fraudView],
          RolePermissionMatrix.allows(
            entry.value,
            AppPermission.viewFraudAlerts,
          ),
          reason: 'fraud.view drifted for ${entry.key}',
        );
        expect(
          offline[PermissionKeys.fraudResolve],
          RolePermissionMatrix.allows(
            entry.value,
            AppPermission.resolveFraudAlerts,
          ),
          reason: 'fraud.resolve drifted for ${entry.key}',
        );
        expect(
          offline[PermissionKeys.auditLogsVerify],
          RolePermissionMatrix.allows(
            entry.value,
            AppPermission.verifyAuditChain,
          ),
          reason: 'audit_logs.verify drifted for ${entry.key}',
        );
      }
    });
  });
}
