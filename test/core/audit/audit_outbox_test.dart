import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/audit_outbox_dao.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/device/device_identity_service.dart';
import 'package:pos/core/device/device_info_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

class MockAuthContextDao extends Mock implements AuthContextDao {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

class MockDeviceIdentityService extends Mock
    implements DeviceIdentityService {}

/// Covers the atomic refund→audit outbox (P1.2): an entry staged inside a
/// transaction becomes a chained row on drain, exactly once, and survives the
/// tenant-guard drop that used to silently lose post-commit audit writes.
void main() {
  late AppDatabase db;
  late AuditLogsDao dao;
  late AuditOutboxDao outboxDao;
  late MockDeviceIdentityService deviceIdentity;
  late ActiveBusinessContext activeBusinessContext;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = AuditLogsDao(db);
    outboxDao = AuditOutboxDao(db);
    deviceIdentity = MockDeviceIdentityService();
    when(() => deviceIdentity.getDeviceUid()).thenAnswer((_) async => 'dev1');
    when(() => deviceIdentity.wasRestoredFromStorage).thenReturn(false);
    when(() => deviceIdentity.getChainLabel(any())).thenAnswer(
      (inv) => (inv.positionalArguments[0] as Future<String> Function())(),
    );
    when(() => deviceIdentity.getLastLocalHeadSeq(any(), any()))
        .thenAnswer((_) async => null);
    when(() => deviceIdentity.setLastLocalHeadSeq(any(), any(), any()))
        .thenAnswer((_) async {});
    activeBusinessContext = ActiveBusinessContext()
      ..set(
        userId: 'user1',
        businessId: 'biz1',
        branchId: 'branch1',
        fullName: 'Harry',
      );
  });

  tearDown(() async {
    await db.close();
  });

  AuditLogService buildService() {
    final deviceInfo = MockDeviceInfoService();
    when(() => deviceInfo.getDeviceLabel())
        .thenAnswer((_) async => 'Pixel 7 · Android 14');
    return AuditLogService(
      dao: dao,
      outboxDao: outboxDao,
      authContextDao: MockAuthContextDao(),
      activeBusinessContext: activeBusinessContext,
      deviceInfoService: deviceInfo,
      deviceIdentityService: deviceIdentity,
    );
  }

  test('an enqueued entry commits with its transaction and drains to a chained '
      'row', () async {
    final service = buildService();
    await db.transaction(() async {
      await service.enqueueInTransaction(
        actionType: AuditLogActionType.refundCreated,
        entityType: 'refund',
        entityId: 'refund-1',
        businessId: 'biz1',
        description: 'refund',
        branchId: 'branch1',
        userId: 'user1',
      );
    });

    // Staged, not yet a chained row.
    expect(await dao.getByBusiness('biz1'), isEmpty);
    expect(await outboxDao.getPending(), hasLength(1));

    await service.drainOutbox();

    final rows = await dao.getByBusiness('biz1');
    expect(rows, hasLength(1));
    expect(rows.single.entityId, 'refund-1');
    expect(rows.single.seq, 1);
    expect(rows.single.entryHash, isNotNull);
    // The staged row is consumed in the same transaction as the chained insert.
    expect(await outboxDao.getPending(), isEmpty);
  });

  test('draining twice does not double-log (idempotent)', () async {
    final service = buildService();
    await db.transaction(() async {
      await service.enqueueInTransaction(
        actionType: AuditLogActionType.refundCreated,
        entityType: 'refund',
        entityId: 'refund-1',
        businessId: 'biz1',
        description: 'refund',
      );
    });
    await service.drainOutbox();
    await service.drainOutbox();
    expect(await dao.getByBusiness('biz1'), hasLength(1));
  });

  test('drain writes the entry even when the active tenant has moved on '
      '(no silent drop)', () async {
    final service = buildService();
    await db.transaction(() async {
      await service.enqueueInTransaction(
        actionType: AuditLogActionType.refundCreated,
        entityType: 'refund',
        entityId: 'refund-1',
        businessId: 'biz1',
        description: 'refund',
        branchId: 'branch1',
        userId: 'user1',
      );
    });

    // The active context switches to another business before the drain — the
    // old code path would drop the log under the tenant guard.
    activeBusinessContext.set(
      userId: 'user2',
      businessId: 'biz2',
      branchId: 'branch2',
      fullName: 'Other',
    );

    await service.drainOutbox();

    final rows = await dao.getByBusiness('biz1');
    expect(rows, hasLength(1), reason: 'outbox businessId is trusted');
    expect(await outboxDao.getPending(), isEmpty);
  });
}
