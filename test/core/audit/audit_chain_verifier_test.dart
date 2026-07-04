import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/audit/audit_chain_verifier.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/device/device_identity_service.dart';
import 'package:pos/core/device/device_info_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

class MockAuthContextDao extends Mock implements AuthContextDao {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

class MockDeviceIdentityService extends Mock
    implements DeviceIdentityService {}

void main() {
  late AppDatabase db;
  late AuditLogsDao dao;
  late MockDeviceIdentityService deviceIdentityService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = AuditLogsDao(db);
    deviceIdentityService = MockDeviceIdentityService();
    when(() => deviceIdentityService.getDeviceUid())
        .thenAnswer((_) async => 'dev-uid-A');
    when(() => deviceIdentityService.wasRestoredFromStorage).thenReturn(false);
    // Stable chain label resolves through the passed callback (prod behavior).
    when(() => deviceIdentityService.getChainLabel(any())).thenAnswer(
      (inv) => (inv.positionalArguments[0] as Future<String> Function())(),
    );
    when(() => deviceIdentityService.getLastLocalHeadSeq(any(), any()))
        .thenAnswer((_) async => null);
    when(() => deviceIdentityService.setLastLocalHeadSeq(any(), any(), any()))
        .thenAnswer((_) async {});
  });

  tearDown(() async {
    await db.close();
  });

  /// Writes [count] chained rows through the real service, so the chains
  /// under test are exactly what production writes.
  Future<void> seedChain({int count = 4}) async {
    final deviceInfo = MockDeviceInfoService();
    when(() => deviceInfo.getDeviceLabel())
        .thenAnswer((_) async => 'Pixel 7 · Android 14');
    final service = AuditLogService(
      dao: dao,
      authContextDao: MockAuthContextDao(),
      activeBusinessContext: ActiveBusinessContext()
        ..set(
          userId: 'user1',
          businessId: 'biz1',
          branchId: 'branch1',
          fullName: 'Harry',
        ),
      deviceInfoService: deviceInfo,
      deviceIdentityService: deviceIdentityService,
    );
    for (var i = 1; i <= count; i++) {
      await service.log(
        actionType: AuditLogActionType.saleCreated,
        entityType: 'transaction',
        description: 'sale $i',
        metadata: {'total': i * 10},
      );
    }
  }

  AuditChainVerifier buildVerifier({ChainHeadsFetcher? fetchChainHeads}) {
    return AuditChainVerifier(
      dao: dao,
      deviceIdentityService: deviceIdentityService,
      fetchChainHeads: fetchChainHeads,
    );
  }

  test('a clean chain verifies with no breaks', () async {
    await seedChain();
    final result = await buildVerifier().verify(businessId: 'biz1');

    expect(result.isClean, isTrue);
    expect(result.serverCheckRan, isFalse);
    final report = result.devices.single;
    expect(report.deviceUid, 'dev-uid-A');
    expect(report.isThisDevice, isTrue);
    expect(report.firstCheckedSeq, 1);
    expect(report.localHeadSeq, 4);
    expect(report.checkedCount, 4);
  });

  test('mutating one row yields exactly one hash break at that seq', () async {
    await seedChain();
    await db.customStatement(
      "UPDATE audit_logs SET description = 'tampered' WHERE seq = 2",
    );

    final result = await buildVerifier().verify(businessId: 'biz1');
    expect(result.totalBreaks, 1);
    final b = result.devices.single.breaks.single;
    expect(b.reason, AuditChainBreakReason.hashMismatch);
    expect(b.seq, 2);
  });

  test('deleting a middle row yields exactly one seq-gap break', () async {
    await seedChain();
    await db.customStatement('DELETE FROM audit_logs WHERE seq = 3');

    final result = await buildVerifier().verify(businessId: 'biz1');
    expect(result.totalBreaks, 1);
    final b = result.devices.single.breaks.single;
    expect(b.reason, AuditChainBreakReason.seqGap);
    expect(b.seq, 4);
  });

  test('a pruned head (missing oldest rows) is a trusted start, not a break',
      () async {
    await seedChain();
    await db.customStatement('DELETE FROM audit_logs WHERE seq <= 2');

    final result = await buildVerifier().verify(businessId: 'biz1');
    expect(result.isClean, isTrue);
    expect(result.devices.single.firstCheckedSeq, 3);
  });

  test('a seq-1 row not anchored to genesis is a link break', () async {
    await seedChain(count: 1);
    await db.customStatement(
      "UPDATE audit_logs SET prev_hash = 'forged' WHERE seq = 1",
    );

    final result = await buildVerifier().verify(businessId: 'biz1');
    final reasons = result.devices.single.breaks.map((b) => b.reason);
    expect(reasons, contains(AuditChainBreakReason.linkMismatch));
  });

  test('pre-chain NULL-seq rows are skipped entirely', () async {
    // Simulates rows written before v53 (or server-trigger rows).
    await db.customStatement(
      "INSERT INTO audit_logs (id, business_id, branch_id, user_id, "
      "action_type, entity_type, description, metadata, device_id, created_at) "
      "VALUES ('legacy1', 'biz1', '', '', 'SALE_CREATED', 'transaction', "
      "'pre-chain', '{}', 'unknown', 1700000000)",
    );
    await seedChain(count: 2);

    final result = await buildVerifier().verify(businessId: 'biz1');
    expect(result.isClean, isTrue);
    expect(result.devices.single.checkedCount, 2);
  });

  group('server high-water check', () {
    test('flags a truncated tail only for this device', () async {
      await seedChain(); // local head = 4
      final result = await buildVerifier(
        fetchChainHeads: () async => [
          {'device_uid': 'dev-uid-A', 'max_seq': 9, 'last_at': null},
          {'device_uid': 'dev-uid-OTHER', 'max_seq': 99, 'last_at': null},
        ],
      ).verify(businessId: 'biz1');

      expect(result.serverCheckRan, isTrue);
      final mine =
          result.devices.singleWhere((d) => d.deviceUid == 'dev-uid-A');
      expect(mine.breaks.single.reason, AuditChainBreakReason.truncatedTail);
      expect(mine.serverHeadSeq, 9);

      // The other device has no local rows — informational only, no break.
      final other =
          result.devices.singleWhere((d) => d.deviceUid == 'dev-uid-OTHER');
      expect(other.isClean, isTrue);
      expect(other.localHeadSeq, isNull);
      expect(other.serverHeadSeq, 99);
    });

    test('matching heads are clean; a fetch failure degrades gracefully',
        () async {
      await seedChain();
      final clean = await buildVerifier(
        fetchChainHeads: () async => [
          {'device_uid': 'dev-uid-A', 'max_seq': 4, 'last_at': null},
        ],
      ).verify(businessId: 'biz1');
      expect(clean.isClean, isTrue);
      expect(clean.serverCheckRan, isTrue);

      final offline = await buildVerifier(
        fetchChainHeads: () async => throw Exception('offline'),
      ).verify(businessId: 'biz1');
      expect(offline.isClean, isTrue);
      expect(offline.serverCheckRan, isFalse);
    });
  });
}
