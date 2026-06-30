import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/audit_logs/data/datasources/audit_log_remote_ds.dart';
import 'package:pos/features/audit_logs/data/repositories/audit_log_repository_impl.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

class MockAuditLogsDao extends Mock implements AuditLogsDao {}

class MockAuditLogRemoteDs extends Mock implements AuditLogRemoteDs {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockAuditLogsDao dao;
  late MockAuditLogRemoteDs remoteDs;
  late MockConnectivityService connectivityService;
  late AuditLogRepositoryImpl repository;

  setUp(() {
    dao = MockAuditLogsDao();
    remoteDs = MockAuditLogRemoteDs();
    connectivityService = MockConnectivityService();
    repository = AuditLogRepositoryImpl(
      dao: dao,
      remoteDs: remoteDs,
      connectivityService: connectivityService,
    );
  });

  group('getRemoteUserLogs', () {
    test('maps a raw Supabase row into an AuditLog entity', () async {
      when(
        () => remoteDs.getByUser(
          'biz1',
          'auth1',
          actionType: AuditLogActionType.userLogin.value,
          limit: 1,
        ),
      ).thenAnswer(
        (_) async => [
          {
            'id': 'log1',
            'business_id': 'biz1',
            'branch_id': 'branch1',
            'user_id': 'auth1',
            'action_type': AuditLogActionType.userLogin.value,
            'entity_type': 'user',
            'entity_id': null,
            'description': 'User signed in',
            'metadata': {'_user_name': 'Harry'},
            'device_id': 'Pixel 7 · Android 14',
            'created_at': '2026-06-28T01:31:47+00:00',
          },
        ],
      );

      final logs = await repository.getRemoteUserLogs(
        businessId: 'biz1',
        userId: 'auth1',
        actionType: AuditLogActionType.userLogin.value,
        limit: 1,
      );

      expect(logs.single.actionType, AuditLogActionType.userLogin);
      expect(logs.single.deviceId, 'Pixel 7 · Android 14');
      expect(logs.single.userName, 'Harry');
      expect(logs.single.createdAt.toUtc(), DateTime.utc(2026, 6, 28, 1, 31, 47));
    });

    test('falls back gracefully when optional fields are null', () async {
      when(
        () => remoteDs.getByUser('biz1', 'auth1', actionType: null, limit: 1),
      ).thenAnswer(
        (_) async => [
          {
            'id': 'log2',
            'business_id': 'biz1',
            'branch_id': null,
            'user_id': 'auth1',
            'action_type': 'SALE_CREATED',
            'entity_type': 'transaction',
            'entity_id': null,
            'description': 'Sale of 100',
            'metadata': null,
            'device_id': null,
            'created_at': '2026-06-28T01:31:47+00:00',
          },
        ],
      );

      final logs = await repository.getRemoteUserLogs(
        businessId: 'biz1',
        userId: 'auth1',
        limit: 1,
      );

      expect(logs.single.branchId, '');
      expect(logs.single.deviceId, 'unknown');
      expect(logs.single.metadata, isEmpty);
    });
  });
}
