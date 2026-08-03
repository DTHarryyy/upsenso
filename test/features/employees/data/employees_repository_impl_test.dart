import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/employee_permissions_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/employees/data/datasources/employees_remote_ds.dart';
import 'package:pos/features/employees/data/employees_repository_impl.dart';
import 'package:pos/features/employees/domain/errors/employee_errors.dart';

class MockEmployeesRemoteDs extends Mock implements EmployeesRemoteDs {}

class MockPermissionRemoteDs extends Mock implements PermissionRemoteDs {}

class MockEntitlementService extends Mock implements EntitlementService {}

class MockAuditLogService extends Mock implements AuditLogService {}

/// Regression cover for the 2026-08-03 "employee creation hangs / no email"
/// bug: `addEmployee` used to await `sendCredentialsEmail` with no timeout,
/// and a server-side seat rejection fell through to a generic error instead
/// of the seat-limit path. See employee_form_dialog_test.dart for the
/// matching client-side route-ordering regression.
void main() {
  late AppDatabase db;
  late MockEmployeesRemoteDs remoteDs;
  late MockPermissionRemoteDs permissionRemoteDs;
  late MockEntitlementService entitlement;
  late MockAuditLogService auditLog;
  late EmployeesRepositoryImpl repo;

  const businessId = 'biz-1';
  const branchId = 'branch-1';

  setUpAll(() {
    registerFallbackValue(AuditLogActionType.employeeCreated);
    registerFallbackValue(EntitlementResource.seats);
  });

  setUp(() async {
    await sl.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remoteDs = MockEmployeesRemoteDs();
    permissionRemoteDs = MockPermissionRemoteDs();
    entitlement = MockEntitlementService();
    auditLog = MockAuditLogService();

    sl.registerSingleton<EntitlementService>(entitlement);
    sl.registerSingleton<AuditLogService>(auditLog);

    when(() => entitlement.canAddAnother(any())).thenAnswer((_) async => true);
    when(() => entitlement.recomputeLocalUsage()).thenAnswer((_) async {});
    when(
      () => auditLog.log(
        actionType: any(named: 'actionType'),
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        entityName: any(named: 'entityName'),
        description: any(named: 'description'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => remoteDs.upsertEmployee(
        id: any(named: 'id'),
        businessId: any(named: 'businessId'),
        authUserId: any(named: 'authUserId'),
        fullName: any(named: 'fullName'),
        email: any(named: 'email'),
        roleId: any(named: 'roleId'),
        roleName: any(named: 'roleName'),
        isActive: any(named: 'isActive'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => remoteDs.assignBranch(
        employeeId: any(named: 'employeeId'),
        branchId: any(named: 'branchId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => permissionRemoteDs.computePermissions(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => remoteDs.getRolesByBusiness(any()),
    ).thenAnswer((_) async => {'cashier': 'role-1'});

    repo = EmployeesRepositoryImpl(
      dao: EmployeesDao(db),
      remoteDs: remoteDs,
      permissionsDao: EmployeePermissionsDao(db),
      permissionRemoteDs: permissionRemoteDs,
    );
  });

  tearDown(() async {
    await sl.reset();
    await db.close();
  });

  void mockAuthAccount({String uid = 'auth-1'}) => when(
    () => remoteDs.createAuthAccount(
      email: any(named: 'email'),
      password: any(named: 'password'),
      businessId: any(named: 'businessId'),
      branchId: any(named: 'branchId'),
      fullName: any(named: 'fullName'),
      roleId: any(named: 'roleId'),
    ),
  ).thenAnswer((_) async => uid);

  group('addEmployee — credentials email', () {
    test(
      'falls back to showing the temp password when the email send throws',
      () async {
        mockAuthAccount();
        when(
          () => remoteDs.sendCredentialsEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          ),
        ).thenThrow(Exception('send-employee-credentials failed (502)'));

        final result = await repo.addEmployee(
          businessId: businessId,
          branchId: branchId,
          fullName: 'Maria Santos',
          email: 'maria@business.com',
          roleName: 'Cashier',
        );

        expect(result.credentialsEmailed, isFalse);
        expect(result.temporaryPassword, isNotNull);
      },
    );

    test(
      'treats a slow email send as a failure rather than hanging the caller',
      () async {
        mockAuthAccount();
        when(
          () => remoteDs.sendCredentialsEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          ),
        ).thenAnswer((_) async {
          // Longer than addEmployee's internal 8s timeout on this call.
          await Future<void>.delayed(const Duration(seconds: 9));
        });

        final result = await repo.addEmployee(
          businessId: businessId,
          branchId: branchId,
          fullName: 'Maria Santos',
          email: 'maria@business.com',
          roleName: 'Cashier',
        );

        expect(result.credentialsEmailed, isFalse);
        expect(result.temporaryPassword, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test('reports success when the email actually sends', () async {
      mockAuthAccount();
      when(
        () => remoteDs.sendCredentialsEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.addEmployee(
        businessId: businessId,
        branchId: branchId,
        fullName: 'Maria Santos',
        email: 'maria@business.com',
        roleName: 'Cashier',
      );

      expect(result.credentialsEmailed, isTrue);
      expect(result.temporaryPassword, isNull);
    });
  });

  group('addEmployee — seat cap', () {
    test(
      'maps the RPC\'s SEAT_LIMIT_REACHED to EmployeeSeatLimitException',
      () async {
        when(
          () => remoteDs.createAuthAccount(
            email: any(named: 'email'),
            password: any(named: 'password'),
            businessId: any(named: 'businessId'),
            branchId: any(named: 'branchId'),
            fullName: any(named: 'fullName'),
            roleId: any(named: 'roleId'),
          ),
        ).thenThrow(
          PostgrestException(
            message: 'SEAT_LIMIT_REACHED: plan allows 3 active seat(s)',
          ),
        );

        await expectLater(
          repo.addEmployee(
            businessId: businessId,
            branchId: branchId,
            fullName: 'Maria Santos',
            email: 'maria@business.com',
            roleName: 'Cashier',
          ),
          throwsA(isA<EmployeeSeatLimitException>()),
        );
      },
    );
  });
}
