import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/business_modules_dao.dart';
import 'package:pos/core/database/daos/employee_permissions_dao.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/permissions/data_scope.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

class MockAuthContextDao extends Mock implements AuthContextDao {}

class MockAuditLogService extends Mock implements AuditLogService {}

class MockEmployeePermissionsDao extends Mock implements EmployeePermissionsDao {}

class MockPermissionRemoteDs extends Mock implements PermissionRemoteDs {}

class MockBusinessModulesDao extends Mock implements BusinessModulesDao {}

BusinessModuleRow _moduleRow(String code, bool enabled) => BusinessModuleRow(
  businessId: 'biz1',
  moduleCode: code,
  enabled: enabled,
  syncedAt: DateTime.now(),
);

void main() {
  late MockAuthContextDao authContextDao;
  late ActiveBusinessContext activeBusinessContext;
  late MockAuditLogService auditLogService;
  late MockEmployeePermissionsDao permissionsDao;
  late MockPermissionRemoteDs permissionRemoteDs;
  late MockBusinessModulesDao businessModulesDao;
  late PermissionService service;

  setUpAll(() {
    registerFallbackValue(AuditLogActionType.permissionDenied);
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    authContextDao = MockAuthContextDao();
    activeBusinessContext = ActiveBusinessContext();
    auditLogService = MockAuditLogService();
    permissionsDao = MockEmployeePermissionsDao();
    permissionRemoteDs = MockPermissionRemoteDs();
    businessModulesDao = MockBusinessModulesDao();

    // guard() always passes exactly these 6 named args (see permission_service.dart).
    when(
      () => auditLogService.log(
        actionType: any(named: 'actionType'),
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        entityName: any(named: 'entityName'),
        description: any(named: 'description'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});

    service = PermissionService(
      authContextDao: authContextDao,
      activeBusinessContext: activeBusinessContext,
      auditLogService: auditLogService,
      permissionsDao: permissionsDao,
      permissionRemoteDs: permissionRemoteDs,
      businessModulesDao: businessModulesDao,
    );
  });

  // Drives the real loadPermissions() path so _permissionsMap is populated
  // exactly the way production code populates it (no private-field pokes).
  Future<void> seedPermissions(Map<String, bool> map) async {
    when(() => permissionsDao.getPermissions(any())).thenAnswer((_) async => map);
    await service.loadPermissions('test-user');
  }

  Future<void> enableModules(Map<String, bool> states) async {
    when(() => businessModulesDao.getAll(any())).thenAnswer(
      (_) async => states.entries.map((e) => _moduleRow(e.key, e.value)).toList(),
    );
    await service.loadEnabledModules('biz1');
  }

  group('can() precedence (pos.* keys — module is always-on, gate-transparent)', () {
    test('role default grant resolves true with no override map loaded', () {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      expect(service.can(PermissionKeys.posUse), isTrue);
    });

    test('role default deny resolves false with no override map loaded', () {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      expect(service.can(PermissionKeys.posVoidSale), isFalse);
    });

    test('explicit override grant beats a role default deny', () async {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      await seedPermissions({PermissionKeys.posVoidSale: true});
      expect(service.can(PermissionKeys.posVoidSale), isTrue);
    });

    test('explicit override deny beats a role default grant', () async {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      await seedPermissions({PermissionKeys.posUse: false});
      expect(service.can(PermissionKeys.posUse), isFalse);
    });

    test('key absent from a loaded map falls back to the role default', () async {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      // Seed a map that doesn't mention posHoldSale at all.
      await seedPermissions({PermissionKeys.posUse: true});
      expect(service.can(PermissionKeys.posHoldSale), isTrue); // cashier default
    });

    test('unknown role with no matrix entry denies by default', () {
      service.setContext(roleName: 'made_up_role', branchId: 'b1', userId: 'u1');
      expect(service.can(PermissionKeys.posUse), isFalse);
    });
  });

  group('module gate', () {
    test('sensitive (non-core) module fails closed before module states load', () {
      service.setContext(roleName: 'Business Owner', branchId: null, userId: 'u1');
      expect(service.can(PermissionKeys.employeesView), isFalse);
    });

    test('core module (pos) fails open before module states load', () {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      expect(service.can(PermissionKeys.posUse), isTrue);
    });

    test('disabled module denies even when the permission itself is granted', () async {
      service.setContext(roleName: 'Business Owner', branchId: null, userId: 'u1');
      await enableModules({'employees': false});
      expect(service.can(PermissionKeys.employeesView), isFalse);
    });

    test('enabled module lets a granted permission through', () async {
      service.setContext(roleName: 'Business Owner', branchId: null, userId: 'u1');
      await enableModules({'employees': true});
      expect(service.can(PermissionKeys.employeesView), isTrue);
    });
  });

  group('nav.* access-key fallback', () {
    test('nav key resolves true via an underlying access key the role holds', () {
      // Cashier: navInventory default is false, but inventoryViewLevels is true.
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      expect(service.can('nav.inventory'), isTrue);
    });

    test('nav key resolves false when neither it nor its access keys are granted', () async {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      await enableModules({'employees': true});
      expect(service.can('nav.employees'), isFalse);
    });
  });

  group('isOwnerRole', () {
    test('true for owner-tier roles and aliases', () {
      for (final name in ['Business Owner', 'Super Admin', 'Owner']) {
        service.setRole(name);
        expect(service.isOwnerRole, isTrue, reason: name);
      }
    });

    test('false for non-owner roles', () {
      service.setRole('Cashier');
      expect(service.isOwnerRole, isFalse);
    });
  });

  group('getDataScope()', () {
    test('role default: Business Owner is unrestricted', () {
      service.setContext(roleName: 'Business Owner', branchId: null, userId: 'u1');
      expect(service.getDataScope().type, DataScopeType.allBranches);
    });

    test('role default: Branch Manager is branch-scoped', () {
      service.setContext(roleName: 'Branch Manager', branchId: 'b1', userId: 'u1');
      final scope = service.getDataScope();
      expect(scope.type, DataScopeType.branchOnly);
      expect(scope.branchId, 'b1');
    });

    test('role default: Cashier is own-only', () {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      final scope = service.getDataScope();
      expect(scope.type, DataScopeType.ownOnly);
      expect(scope.branchId, 'b1');
      expect(scope.userId, 'u1');
    });

    test('loaded map: reports.view_all grants unrestricted scope', () async {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      await seedPermissions({PermissionKeys.reportsViewAll: true});
      expect(service.getDataScope().type, DataScopeType.allBranches);
    });

    test('loaded map: reports.view_branch grants branch scope', () async {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      await seedPermissions({PermissionKeys.reportsViewBranch: true});
      expect(service.getDataScope().type, DataScopeType.branchOnly);
    });

    test('override-deny narrows an owner role default down to own-only', () async {
      service.setContext(roleName: 'Business Owner', branchId: 'b1', userId: 'u1');
      // Owner's role default grants all three broad-scope keys; explicit
      // denies on the map must still win and narrow the resolved scope.
      await seedPermissions({
        PermissionKeys.reportsViewAll: false,
        PermissionKeys.dataCrossBranchAccess: false,
        PermissionKeys.reportsViewBranch: false,
      });
      final scope = service.getDataScope();
      expect(scope.type, DataScopeType.ownOnly);
      expect(scope.branchId, 'b1');
      expect(scope.userId, 'u1');
    });
  });

  group('guard()', () {
    test('grants without writing an audit log when permission is held', () async {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      final result = await service.guard(AppPermission.applyDiscount);
      expect(result.granted, isTrue);
      verifyNever(
        () => auditLogService.log(
          actionType: any(named: 'actionType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          entityName: any(named: 'entityName'),
          description: any(named: 'description'),
          metadata: any(named: 'metadata'),
        ),
      );
    });

    test('denies and writes an audit log entry when permission is missing', () async {
      service.setContext(roleName: 'Cashier', branchId: 'b1', userId: 'u1');
      final result = await service.guard(AppPermission.refundSale);
      expect(result.granted, isFalse);
      expect(result.deniedReason, isNotNull);
      verify(
        () => auditLogService.log(
          actionType: AuditLogActionType.permissionDenied,
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          entityName: any(named: 'entityName'),
          description: any(named: 'description'),
          metadata: any(named: 'metadata'),
        ),
      ).called(1);
    });
  });

  group('canAccessFeature()', () {
    test('denies when module is disabled even though the nav permission is granted', () async {
      service.setContext(roleName: 'Business Owner', branchId: null, userId: 'u1');
      await enableModules({'employees': false});
      expect(service.canAccessFeature(AppFeature.employeeManagement), isFalse);
    });

    test('grants when module is enabled and the role holds the nav-equivalent permission', () async {
      service.setContext(roleName: 'Business Owner', branchId: null, userId: 'u1');
      await enableModules({'employees': true});
      expect(service.canAccessFeature(AppFeature.employeeManagement), isTrue);
    });
  });
}
