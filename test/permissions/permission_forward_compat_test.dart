import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/business_modules_dao.dart';
import 'package:pos/core/database/daos/employee_permissions_dao.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Verifies that a user whose STORED permission matrix predates a newly-added
/// key (the exact situation of every existing user after this feature ships)
/// still resolves that key from their role default — while explicit denies in
/// the stored matrix are preserved.
void main() {
  late AppDatabase db;
  late EmployeePermissionsDao permsDao;
  late PermissionService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    permsDao = EmployeePermissionsDao(db);
    service = PermissionService(
      authContextDao: AuthContextDao(db),
      auditLogService: AuditLogService(
        dao: AuditLogsDao(db),
        authContextDao: AuthContextDao(db),
      ),
      permissionsDao: permsDao,
      permissionRemoteDs: PermissionRemoteDs(
        SupabaseClient('https://example.supabase.co', 'test-anon-key'),
      ),
      businessModulesDao: BusinessModulesDao(db),
    );
  });

  tearDown(() async => db.close());

  test('absent key falls back to role default; explicit deny preserved',
      () async {
    service.setRole('cashier');

    // Simulate a pre-existing cached matrix that does NOT contain the new
    // hold-sale keys, and explicitly denies one capability.
    await permsDao.savePermissions('user-1', {
      PermissionKeys.posUse: true,
      PermissionKeys.posApplyDiscount: false, // explicit deny
    });
    await service.loadPermissions('user-1');

    // New keys are absent from the stored map → resolved from cashier defaults.
    expect(service.can(PermissionKeys.posHoldSale), isTrue);
    expect(service.can(PermissionKeys.navHeldSales), isTrue);

    // Present keys are honored exactly as stored.
    expect(service.can(PermissionKeys.posUse), isTrue);
    expect(service.can(PermissionKeys.posApplyDiscount), isFalse);
  });

  test('inventory staff still cannot hold even via fallback', () async {
    service.setRole('inventory_staff');
    await permsDao.savePermissions('user-2', {
      PermissionKeys.inventoryView: true,
    });
    await service.loadPermissions('user-2');

    expect(service.can(PermissionKeys.posHoldSale), isFalse);
    expect(service.can(PermissionKeys.navHeldSales), isFalse);
  });
}
