import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/device/device_info_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

class MockAuditLogsDao extends Mock implements AuditLogsDao {}

class MockAuthContextDao extends Mock implements AuthContextDao {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

void main() {
  late MockAuditLogsDao dao;
  late MockAuthContextDao authContextDao;
  late MockDeviceInfoService deviceInfoService;
  late ActiveBusinessContext activeBusinessContext;
  late AuditLogService service;

  setUpAll(() {
    registerFallbackValue(const AuditLogsTableCompanion());
  });

  setUp(() {
    dao = MockAuditLogsDao();
    authContextDao = MockAuthContextDao();
    deviceInfoService = MockDeviceInfoService();
    activeBusinessContext = ActiveBusinessContext()
      ..set(
        userId: 'user1',
        businessId: 'biz1',
        branchId: 'branch1',
        fullName: 'Harry',
      );

    when(() => dao.insert(any())).thenAnswer((_) async {});

    service = AuditLogService(
      dao: dao,
      authContextDao: authContextDao,
      activeBusinessContext: activeBusinessContext,
      deviceInfoService: deviceInfoService,
    );
  });

  test('log() writes the device label resolved by DeviceInfoService', () async {
    when(
      () => deviceInfoService.getDeviceLabel(),
    ).thenAnswer((_) async => 'Pixel 7 · Android 14');

    await service.log(
      actionType: AuditLogActionType.saleCreated,
      entityType: 'transaction',
      description: 'Sale of 100',
    );

    final companion =
        verify(() => dao.insert(captureAny())).captured.single
            as AuditLogsTableCompanion;
    expect(companion.deviceId.value, 'Pixel 7 · Android 14');
  });

  test(
    "log() falls back to DeviceInfoService's 'Unknown device' label as-is",
    () async {
      when(
        () => deviceInfoService.getDeviceLabel(),
      ).thenAnswer((_) async => 'Unknown device');

      await service.log(
        actionType: AuditLogActionType.saleCreated,
        entityType: 'transaction',
        description: 'Sale of 100',
      );

      final companion =
          verify(() => dao.insert(captureAny())).captured.single
              as AuditLogsTableCompanion;
      expect(companion.deviceId.value, 'Unknown device');
    },
  );
}
