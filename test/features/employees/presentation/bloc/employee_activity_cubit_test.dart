import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/audit_logs/domain/entities/audit_log.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/presentation/bloc/employee_activity_cubit.dart';
import 'package:pos/features/employees/presentation/bloc/employee_activity_state.dart';

class MockAuditLogRepository extends Mock implements IAuditLogRepository {}

void main() {
  late MockAuditLogRepository repository;

  const employee = Employee(
    id: 'emp1',
    businessId: 'biz1',
    authUserId: 'auth1',
    fullName: 'Harry',
  );

  AuditLog buildLog({
    required AuditLogActionType actionType,
    required DateTime createdAt,
    String deviceId = 'unknown',
  }) {
    return AuditLog(
      id: 'log1',
      businessId: 'biz1',
      branchId: 'branch1',
      userId: 'auth1',
      actionType: actionType,
      entityType: 'employee',
      description: 'test',
      metadata: const {},
      deviceId: deviceId,
      createdAt: createdAt,
      syncStatus: 0,
    );
  }

  setUp(() {
    repository = MockAuditLogRepository();
  });

  group('EmployeeActivityCubit', () {
    final loginTime = DateTime(2026, 6, 29, 9, 30);
    final recentTime = DateTime(2026, 6, 29, 10, 0);

    blocTest<EmployeeActivityCubit, EmployeeActivityState>(
      'emits last login, device and recent activity from the audit trail',
      build: () => EmployeeActivityCubit(repository),
      setUp: () {
        when(
          () => repository.getRemoteUserLogs(
            businessId: 'biz1',
            userId: 'auth1',
            actionType: AuditLogActionType.userLogin.value,
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => [
            buildLog(
              actionType: AuditLogActionType.userLogin,
              createdAt: loginTime,
              deviceId: 'Pixel 7 · Android 14',
            ),
          ],
        );
        when(
          () => repository.getRemoteUserLogs(businessId: 'biz1', userId: 'auth1', limit: 1),
        ).thenAnswer(
          (_) async => [
            buildLog(actionType: AuditLogActionType.saleCreated, createdAt: recentTime),
          ],
        );
      },
      act: (cubit) => cubit.load(employee),
      expect: () => [
        isA<EmployeeActivityLoaded>()
            .having((s) => s.lastLogin, 'lastLogin', loginTime)
            .having((s) => s.device, 'device', 'Pixel 7 · Android 14')
            .having(
              (s) => s.recentActivityLabel,
              'recentActivityLabel',
              'Sale Created',
            )
            .having((s) => s.recentActivityTime, 'recentActivityTime', recentTime),
      ],
    );

    blocTest<EmployeeActivityCubit, EmployeeActivityState>(
      "treats the 'unknown' device placeholder as not captured",
      build: () => EmployeeActivityCubit(repository),
      setUp: () {
        when(
          () => repository.getRemoteUserLogs(
            businessId: 'biz1',
            userId: 'auth1',
            actionType: AuditLogActionType.userLogin.value,
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => [
            buildLog(actionType: AuditLogActionType.userLogin, createdAt: loginTime),
          ],
        );
        when(
          () => repository.getRemoteUserLogs(businessId: 'biz1', userId: 'auth1', limit: 1),
        ).thenAnswer((_) async => []);
      },
      act: (cubit) => cubit.load(employee),
      expect: () => [
        isA<EmployeeActivityLoaded>()
            .having((s) => s.lastLogin, 'lastLogin', loginTime)
            .having((s) => s.device, 'device', isNull)
            .having((s) => s.recentActivityLabel, 'recentActivityLabel', isNull),
      ],
    );

    blocTest<EmployeeActivityCubit, EmployeeActivityState>(
      'emits an empty Loaded state without querying when the employee has no auth account',
      build: () => EmployeeActivityCubit(repository),
      act: (cubit) => cubit.load(
        const Employee(id: 'emp2', businessId: 'biz1', fullName: 'No Auth'),
      ),
      expect: () => [
        isA<EmployeeActivityLoaded>()
            .having((s) => s.lastLogin, 'lastLogin', isNull)
            .having((s) => s.device, 'device', isNull)
            .having((s) => s.recentActivityLabel, 'recentActivityLabel', isNull),
      ],
      verify: (_) {
        verifyNever(
          () => repository.getRemoteUserLogs(
            businessId: any(named: 'businessId'),
            userId: any(named: 'userId'),
          ),
        );
      },
    );

    blocTest<EmployeeActivityCubit, EmployeeActivityState>(
      'emits an empty Loaded state instead of rethrowing when the repository fails',
      build: () => EmployeeActivityCubit(repository),
      setUp: () {
        when(
          () => repository.getRemoteUserLogs(
            businessId: 'biz1',
            userId: 'auth1',
            actionType: AuditLogActionType.userLogin.value,
            limit: 1,
          ),
        ).thenThrow(Exception('boom'));
      },
      act: (cubit) => cubit.load(employee),
      expect: () => [isA<EmployeeActivityLoaded>()],
    );
  });
}
