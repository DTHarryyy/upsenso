import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/permissions/default_permission_matrix.dart';
import 'package:pos/core/permissions/permission_keys.dart';

/// Guards the offline default-permission seeding used when an employee is
/// created (employees_repository_impl `addEmployee`). Procurement grants must be
/// correct per role, role-name normalization must work, and unknown roles must
/// resolve to an explicit empty set (deny-all offline; server is authoritative).
void main() {
  test('owner/super_admin get all procurement grants', () {
    for (final role in ['owner', 'business_owner', 'super_admin']) {
      final m = DefaultPermissionMatrix.forRole(role);
      expect(m[PermissionKeys.procurementView], isTrue, reason: role);
      expect(m[PermissionKeys.procurementCreatePo], isTrue, reason: role);
      expect(m[PermissionKeys.procurementApprovePo], isTrue, reason: role);
      expect(m[PermissionKeys.procurementReceive], isTrue, reason: role);
      expect(m[PermissionKeys.procurementManage], isTrue, reason: role);
    }
  });

  test('branch manager can create/approve/receive procurement', () {
    final m = DefaultPermissionMatrix.forRole('branch_manager');
    expect(m[PermissionKeys.procurementCreatePo], isTrue);
    expect(m[PermissionKeys.procurementApprovePo], isTrue);
    expect(m[PermissionKeys.procurementReceive], isTrue);
  });

  test('inventory staff can receive but not create/approve', () {
    final m = DefaultPermissionMatrix.forRole('inventory_staff');
    expect(m[PermissionKeys.procurementReceive], isTrue);
    expect(m[PermissionKeys.procurementCreatePo] ?? false, isFalse);
    expect(m[PermissionKeys.procurementApprovePo] ?? false, isFalse);
  });

  test('cashier gets no procurement grants', () {
    final m = DefaultPermissionMatrix.forRole('cashier');
    expect(m[PermissionKeys.procurementCreatePo] ?? false, isFalse);
    expect(m[PermissionKeys.procurementReceive] ?? false, isFalse);
  });

  test('role name is normalized (case + spaces)', () {
    final spaced = DefaultPermissionMatrix.forRole('Branch Manager');
    final keyed = DefaultPermissionMatrix.forRole('branch_manager');
    expect(spaced, keyed);
  });

  test('unknown or null role resolves to an explicit empty set', () {
    expect(DefaultPermissionMatrix.forRole('some_custom_role'), isEmpty);
    expect(DefaultPermissionMatrix.forRole(null), isEmpty);
  });
}
