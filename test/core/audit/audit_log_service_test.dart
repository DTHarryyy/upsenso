import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/audit/audit_hash.dart';
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
  late MockAuthContextDao authContextDao;
  late MockDeviceInfoService deviceInfoService;
  late MockDeviceIdentityService deviceIdentityService;
  late ActiveBusinessContext activeBusinessContext;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = AuditLogsDao(db);
    authContextDao = MockAuthContextDao();
    deviceInfoService = MockDeviceInfoService();
    deviceIdentityService = MockDeviceIdentityService();
    activeBusinessContext = ActiveBusinessContext()
      ..set(
        userId: 'user1',
        businessId: 'biz1',
        branchId: 'branch1',
        fullName: 'Harry',
      );

    when(() => deviceInfoService.getDeviceLabel())
        .thenAnswer((_) async => 'Pixel 7 · Android 14');
    when(() => deviceIdentityService.getDeviceUid())
        .thenAnswer((_) async => 'dev-uid-A');
    // Default: a freshly-minted uid (a genuine first run) — genesis at seq 1
    // is safe. The reinstall/wiped-DB tests override this to true.
    when(() => deviceIdentityService.wasRestoredFromStorage).thenReturn(false);
    // Stable chain label resolves through the passed callback (prod behavior),
    // plus the eviction-sentinel accessors used on every write.
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

  AuditLogService buildService({AuditChainHeadResolver? resolver}) {
    return AuditLogService(
      dao: dao,
      authContextDao: authContextDao,
      activeBusinessContext: activeBusinessContext,
      deviceInfoService: deviceInfoService,
      deviceIdentityService: deviceIdentityService,
      chainHeadResolver: resolver,
    );
  }

  Future<List<AuditLogRow>> rowsBySeq() async {
    final rows = await dao.getByBusiness('biz1', limit: 100);
    rows.sort((a, b) => (a.seq ?? 0).compareTo(b.seq ?? 0));
    return rows;
  }

  Future<void> logSale(AuditLogService service, {String description = 'Sale'}) {
    return service.log(
      actionType: AuditLogActionType.saleCreated,
      entityType: 'transaction',
      description: description,
      metadata: {'total': 100},
    );
  }

  test('writes the device label and the stable device uid', () async {
    final service = buildService();
    await logSale(service);

    final rows = await rowsBySeq();
    expect(rows, hasLength(1));
    expect(rows.single.deviceId, 'Pixel 7 · Android 14');
    expect(rows.single.deviceUid, 'dev-uid-A');
  });

  test('genesis row starts at seq 1 with the 64-zero prev hash', () async {
    final service = buildService();
    await logSale(service);

    final row = (await rowsBySeq()).single;
    expect(row.seq, 1);
    expect(row.prevHash, kAuditGenesisHash);
    expect(row.entryHash, isNotNull);
  });

  test('seq increments and prevHash links to the prior entryHash', () async {
    final service = buildService();
    await logSale(service, description: 'one');
    await logSale(service, description: 'two');
    await logSale(service, description: 'three');

    final rows = await rowsBySeq();
    expect(rows.map((r) => r.seq), [1, 2, 3]);
    expect(rows[1].prevHash, rows[0].entryHash);
    expect(rows[2].prevHash, rows[1].entryHash);
  });

  test('stored entryHash is recomputable from the stored row', () async {
    final service = buildService();
    await logSale(service);
    await logSale(service, description: 'second');

    for (final row in await rowsBySeq()) {
      final payload = canonicalAuditPayload(
        actionType: row.actionType,
        branchId: row.branchId,
        businessId: row.businessId,
        createdAt: row.createdAt,
        description: row.description,
        deviceUid: row.deviceUid!,
        entityId: row.entityId,
        entityType: row.entityType,
        metadataJson: row.metadata,
        seq: row.seq!,
        userId: row.userId,
      );
      expect(
        auditEntryHash(prevHash: row.prevHash!, canonicalPayload: payload),
        row.entryHash,
        reason: 'writer and verifier must agree on seq ${row.seq}',
      );
    }
  });

  test('concurrent log() calls never duplicate a seq', () async {
    final service = buildService();
    await Future.wait([
      for (var i = 0; i < 5; i++) logSale(service, description: 'sale $i'),
    ]);

    final rows = await rowsBySeq();
    expect(rows.map((r) => r.seq), [1, 2, 3, 4, 5]);
    for (var i = 1; i < rows.length; i++) {
      expect(rows[i].prevHash, rows[i - 1].entryHash);
    }
  });

  test('genesis-resume continues from the server head after a reinstall',
      () async {
    var resolverCalls = 0;
    final service = buildService(
      resolver: (uid) async {
        resolverCalls++;
        expect(uid, 'dev-uid-A');
        return (seq: 41, hash: 'serverheadhash');
      },
    );

    await logSale(service);
    await logSale(service, description: 'after resume');

    final rows = await rowsBySeq();
    expect(rows.first.seq, 42);
    expect(rows.first.prevHash, 'serverheadhash');
    expect(rows.last.seq, 43);
    // Resume is a once-per-(session, business) check, not per write.
    expect(resolverCalls, 1);
  });

  test('a RESTORED uid that is offline at an empty-chain start rotates',
      () async {
    // Reinstall shape: uid survived storage, local DB empty, server
    // unreachable — must not reuse the restored uid at seq 1.
    when(() => deviceIdentityService.wasRestoredFromStorage).thenReturn(true);
    when(() => deviceIdentityService.rotate())
        .thenAnswer((_) async => 'dev-uid-FRESH');
    final service = buildService(
      resolver: (_) async => throw Exception('offline'),
    );

    await logSale(service);

    final row = (await rowsBySeq()).single;
    expect(row.deviceUid, 'dev-uid-FRESH');
    expect(row.seq, 1);
    expect(row.prevHash, kAuditGenesisHash);
    verify(() => deviceIdentityService.rotate()).called(1);
  });

  test('a RESTORED uid with a null server head rotates (the 2026-07-03 '
      'regression: never restart the stored uid at seq 1)', () async {
    when(() => deviceIdentityService.wasRestoredFromStorage).thenReturn(true);
    when(() => deviceIdentityService.rotate())
        .thenAnswer((_) async => 'dev-uid-FRESH');
    final service = buildService(resolver: (_) async => null);
    await logSale(service);

    final row = (await rowsBySeq()).single;
    expect(row.deviceUid, 'dev-uid-FRESH');
    expect(row.seq, 1);
    verify(() => deviceIdentityService.rotate()).called(1);
  });

  test('a freshly-minted uid with no server head starts genesis under the same '
      'uid (true first run — no wasteful rotation)', () async {
    // Default wasRestoredFromStorage=false → this is a genuine first run.
    final service = buildService(resolver: (_) async => null);
    await logSale(service);

    final row = (await rowsBySeq()).single;
    expect(row.deviceUid, 'dev-uid-A');
    expect(row.seq, 1);
    expect(row.prevHash, kAuditGenesisHash);
    verifyNever(() => deviceIdentityService.rotate());
  });

  test('reconcileConflictedTail re-chains the unsynced tail past the server '
      'head', () async {
    // Seed a restarted local chain at seq 1-3 (resume from a fake head of 0).
    final seeder =
        buildService(resolver: (_) async => (seq: 0, hash: kAuditGenesisHash));
    await logSale(seeder, description: 'a');
    await logSale(seeder, description: 'b');
    await logSale(seeder, description: 'c');
    expect((await rowsBySeq()).map((r) => r.seq), [1, 2, 3]);

    // The server already holds this uid up to seq 55 → heal continues past it.
    final serverHeadHash = 'a' * 64;
    final healService = buildService(
      resolver: (_) async => (seq: 55, hash: serverHeadHash),
    );
    await healService.reconcileConflictedTail('biz1');

    final rows = await rowsBySeq();
    // The 3 transplanted rows continue past the server head; the heal also
    // appends one AUDIT_CHAIN_RECONCILED marker entry (seq 59) so the
    // transplant is explainable and TIME_REVERSAL can tell it from a clock roll.
    final transplanted =
        rows.where((r) => r.actionType == 'SALE_CREATED').toList();
    expect(transplanted.map((r) => r.seq), [56, 57, 58]);
    expect(rows.last.actionType, 'AUDIT_CHAIN_RECONCILED');
    expect(rows.last.seq, 59);
    expect(transplanted.first.prevHash, serverHeadHash);
    // Chain links internally and every hash recomputes from stored fields.
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final payload = canonicalAuditPayload(
        actionType: row.actionType,
        branchId: row.branchId,
        businessId: row.businessId,
        createdAt: row.createdAt,
        description: row.description,
        deviceUid: row.deviceUid!,
        entityId: row.entityId,
        entityType: row.entityType,
        metadataJson: row.metadata,
        seq: row.seq!,
        userId: row.userId,
      );
      expect(
        auditEntryHash(prevHash: row.prevHash!, canonicalPayload: payload),
        row.entryHash,
      );
      if (i > 0) expect(row.prevHash, rows[i - 1].entryHash);
    }
    // Re-queued for push, conflict error cleared.
    expect(rows.every((r) => r.syncError == null), isTrue);
  });

  test('tenant guard still drops logs for a non-active business', () async {
    final service = buildService();
    await service.log(
      actionType: AuditLogActionType.saleCreated,
      entityType: 'transaction',
      description: 'cross-tenant',
      businessId: 'biz-OTHER',
    );

    expect(await dao.getByBusiness('biz-OTHER'), isEmpty);
    expect(await dao.getByBusiness('biz1'), isEmpty);
  });
}
