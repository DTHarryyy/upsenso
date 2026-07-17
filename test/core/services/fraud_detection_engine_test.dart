import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/fraud_candidates_dao.dart';
import 'package:pos/core/database/daos/fraud_flags_dao.dart';
import 'package:pos/core/database/daos/sync_state_dao.dart';
import 'package:pos/core/device/device_identity_service.dart';
import 'package:pos/core/device/device_info_service.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/services/fraud_detection_engine.dart';
import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/excessive_refunds_rule.dart';
import 'package:pos/core/session/active_business_context.dart';

class MockAuthContextDao extends Mock implements AuthContextDao {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

class MockDeviceIdentityService extends Mock implements DeviceIdentityService {}

class MockPermissionService extends Mock implements PermissionService {}

/// Minimal rule for gating tests.
class _MirrorOnlyRule implements FraudRule {
  @override
  String get code => 'MIRROR_ONLY';

  @override
  bool get requiresFullAuditMirror => true;

  int calls = 0;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    calls++;
    return const [];
  }
}

/// Emits a fixed draft under a chosen rule code — used to drive the
/// confirmation pipeline (TIME_REVERSAL is confirmation-gated, not
/// mirror-dependent, so promotion needs only two sightings 30min apart).
class _StubRule implements FraudRule {
  _StubRule(this._code);
  final String _code;
  bool emit = true;

  @override
  String get code => _code;

  @override
  bool get requiresFullAuditMirror => false;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    if (!emit) return const [];
    return [
      FraudFlagDraft(
        ruleCode: _code,
        severity: FraudSeverity.high,
        title: 'stub',
        description: 'stub',
        dedupeKey: '$_code|incident-1',
        detectedAt: ctx.now,
        evidence: const [],
      ),
    ];
  }
}

void main() {
  late AppDatabase db;
  late FraudFlagsDao flagsDao;
  late FraudCandidatesDao candidatesDao;
  late SyncStateDao syncStateDao;
  late AuditLogsDao auditDao;
  late MockPermissionService permissionService;
  late ActiveBusinessContext activeBusinessContext;
  late AuditLogService auditLogService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    flagsDao = FraudFlagsDao(db);
    candidatesDao = FraudCandidatesDao(db);
    syncStateDao = SyncStateDao(db);
    auditDao = AuditLogsDao(db);
    permissionService = MockPermissionService();
    when(() => permissionService.can(any())).thenReturn(true);
    activeBusinessContext = ActiveBusinessContext()
      ..set(
        userId: 'owner1',
        businessId: 'biz1',
        branchId: 'br1',
        fullName: 'Owner',
      );

    final deviceInfo = MockDeviceInfoService();
    when(() => deviceInfo.getDeviceLabel()).thenAnswer((_) async => 'Device');
    final deviceIdentity = MockDeviceIdentityService();
    when(() => deviceIdentity.getDeviceUid()).thenAnswer((_) async => 'dev1');
    when(() => deviceIdentity.wasRestoredFromStorage).thenReturn(false);
    when(() => deviceIdentity.getChainLabel(any())).thenAnswer(
      (inv) => (inv.positionalArguments[0] as Future<String> Function())(),
    );
    when(() => deviceIdentity.getLastLocalHeadSeq(any(), any()))
        .thenAnswer((_) async => null);
    when(() => deviceIdentity.setLastLocalHeadSeq(any(), any(), any()))
        .thenAnswer((_) async {});
    auditLogService = AuditLogService(
      dao: auditDao,
      authContextDao: MockAuthContextDao(),
      activeBusinessContext: activeBusinessContext,
      deviceInfoService: deviceInfo,
      deviceIdentityService: deviceIdentity,
    );
  });

  tearDown(() async {
    await db.close();
  });

  FraudDetectionEngine buildEngine(List<FraudRule> rules) {
    return FraudDetectionEngine(
      db: db,
      flagsDao: flagsDao,
      candidatesDao: candidatesDao,
      syncStateDao: syncStateDao,
      auditLogService: auditLogService,
      permissionService: permissionService,
      activeBusinessContext: activeBusinessContext,
      rules: rules,
    );
  }

  Future<void> seedBusiness({String ownerId = 'owner1'}) {
    return db.customStatement(
      'INSERT INTO businesses (id, name, owner_id, template_id, created_at) '
      "VALUES ('biz1', 'Test', ?, 'tpl', 1700000000)",
      [ownerId],
    );
  }

  Future<void> seedRefunds({
    String user = 'cash1',
    int count = 6,
    DateTime? at,
  }) async {
    final t = (at ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    for (var i = 0; i < count; i++) {
      await db.customStatement(
        'INSERT INTO refunds (id, transaction_id, business_id, branch_id, '
        'refunded_by, total_amount, created_at, updated_at, client_updated_at) '
        "VALUES ('r${at?.millisecondsSinceEpoch ?? ''}_$i', 'tx$i', 'biz1', "
        "'br1', ?, 100, ?, ?, ?)",
        [user, t, t, t],
      );
    }
  }

  /// Sets the M1 "chain era" cutoff by inserting the earliest chained audit row.
  Future<void> seedM1Cutoff(DateTime at) {
    return db.customStatement(
      'INSERT INTO audit_logs (id, business_id, branch_id, user_id, '
      'action_type, entity_type, description, metadata, device_id, '
      'created_at, seq, device_uid) '
      "VALUES ('m1cut', 'biz1', 'br1', 'owner1', 'SALE_CREATED', "
      "'transaction', 'x', '{}', 'D', ?, 1, 'devX')",
      [at.millisecondsSinceEpoch ~/ 1000],
    );
  }

  Future<List<FraudFlagRow>> allFlags() =>
      flagsDao.watchByBusiness('biz1').first;

  group('confirmation pipeline', () {
    test('a first sighting of a confirmation-gated rule stages a candidate, '
        'not a flag', () async {
      await seedBusiness();
      await buildEngine([_StubRule('TIME_REVERSAL')]).runSweep();

      expect(await allFlags(), isEmpty);
      final candidate =
          await candidatesDao.getByKey('biz1', 'TIME_REVERSAL|incident-1');
      expect(candidate, isNotNull);
      expect(candidate!.seenCount, 1);
    });

    test('a candidate re-seen after the gap and enough sightings is promoted',
        () async {
      await seedBusiness();
      // Pre-seed a first sighting from >30 min ago with the same signature
      // (empty evidence → '[]') as the stub emits.
      await candidatesDao.insertCandidate(
        businessId: 'biz1',
        dedupeKey: 'TIME_REVERSAL|incident-1',
        ruleCode: 'TIME_REVERSAL',
        signature: '[]',
        seenAt: DateTime.now().subtract(const Duration(minutes: 40)),
      );

      await buildEngine([_StubRule('TIME_REVERSAL')]).runSweep();

      final flags = await allFlags();
      expect(flags, hasLength(1));
      expect(flags.single.ruleCode, 'TIME_REVERSAL');
      // Promoted candidates are cleared.
      expect(
        await candidatesDao.getByKey('biz1', 'TIME_REVERSAL|incident-1'),
        isNull,
      );
    });

    test('a candidate that stops matching is dropped silently (auto-resolve)',
        () async {
      await seedBusiness();
      final rule = _StubRule('TIME_REVERSAL');
      final engine = buildEngine([rule]);

      await engine.runSweep(); // stages the candidate
      expect(
        await candidatesDao.getByKey('biz1', 'TIME_REVERSAL|incident-1'),
        isNotNull,
      );

      rule.emit = false; // the condition resolved itself
      await engine.runSweep();

      expect(
        await candidatesDao.getByKey('biz1', 'TIME_REVERSAL|incident-1'),
        isNull,
      );
      expect(await allFlags(), isEmpty);
    });
  });

  test('a sweep persists a flag once and re-sweeps converge (dedupe)',
      () async {
    await seedBusiness();
    await seedRefunds();
    final engine = buildEngine([ExcessiveRefundsRule()]);

    await engine.runSweep();
    await engine.runSweep();

    final flags = await allFlags();
    expect(flags, hasLength(1));
    expect(flags.single.ruleCode, 'EXCESSIVE_REFUNDS');
    expect(flags.single.severity, 'high');
  });

  test('every NEW flag leaves a chained audit trace', () async {
    await seedBusiness();
    await seedRefunds();
    final engine = buildEngine([ExcessiveRefundsRule()]);

    await engine.runSweep();
    await engine.runSweep(); // dedupe: no second audit entry

    final raised = await auditDao.getByBusiness(
      'biz1',
      actionType: 'FRAUD_FLAG_RAISED',
    );
    expect(raised, hasLength(1));
    // The trace itself is chained — tamper-evident.
    expect(raised.single.seq, isNotNull);
    expect(raised.single.entryHash, isNotNull);
  });

  test('owner-as-subject flags are downgraded, not dropped', () async {
    await seedBusiness(ownerId: 'owner1');
    await seedRefunds(user: 'owner1');
    final engine = buildEngine([ExcessiveRefundsRule()]);

    await engine.runSweep();

    final flags = await allFlags();
    expect(flags, hasLength(1));
    expect(flags.single.severity, 'low');
    expect(flags.single.evidence, contains('business owner'));
  });

  test('incremental runs only the requested rules', () async {
    await seedBusiness();
    await seedRefunds();
    final engine = buildEngine([ExcessiveRefundsRule()]);

    await engine.runIncremental(const {'HIGH_DISCOUNT'});
    expect(await allFlags(), isEmpty);

    await engine.runIncremental(const {'EXCESSIVE_REFUNDS'});
    expect(await allFlags(), hasLength(1));
  });

  test('full-audit-mirror rules are skipped without audit_logs.view',
      () async {
    await seedBusiness();
    final rule = _MirrorOnlyRule();
    final engine = buildEngine([rule]);

    when(() => permissionService.can(PermissionKeys.auditLogsView))
        .thenReturn(false);
    await engine.runSweep();
    expect(rule.calls, 0);

    when(() => permissionService.can(PermissionKeys.auditLogsView))
        .thenReturn(true);
    await engine.runSweep();
    expect(rule.calls, 1);
  });

  test('resolve() only touches triage fields and keeps the INSERT path for '
      'a never-uploaded flag', () async {
    await seedBusiness();
    await seedRefunds();
    final engine = buildEngine([ExcessiveRefundsRule()]);
    await engine.runSweep();

    final flag = (await allFlags()).single;
    await flagsDao.resolve(
      id: flag.id,
      status: 'resolved',
      resolvedBy: 'owner1',
      resolutionNote: 'checked with the cashier',
    );

    final updated = (await allFlags()).single;
    expect(updated.status, 'resolved');
    expect(updated.resolvedBy, 'owner1');
    // Freshly swept = never uploaded: must stay pendingUpload so the first
    // sync still INSERTs the flag (with its triage) instead of issuing an
    // UPDATE that matches nothing server-side.
    expect(updated.syncStatus, 0); // pendingUpload
    expect(updated.evidence, flag.evidence); // forensic fields untouched
    expect(updated.dedupeKey, flag.dedupeKey);
  });

  group('post-M1-install scoping', () {
    test('ignores refund abuse from before M1 first ran', () async {
      await seedBusiness();
      final cutoff = DateTime.now().subtract(const Duration(days: 10));
      await seedM1Cutoff(cutoff);
      // 6 refunds a day BEFORE the cutoff — within the 30d window but
      // pre-M1, so they must not surface.
      await seedRefunds(
        count: 6,
        at: cutoff.subtract(const Duration(days: 1)),
      );

      await buildEngine([ExcessiveRefundsRule()]).runSweep();
      expect(await allFlags(), isEmpty);
    });

    test('flags refund abuse after M1 first ran', () async {
      await seedBusiness();
      await seedM1Cutoff(DateTime.now().subtract(const Duration(days: 10)));
      await seedRefunds(count: 6); // today, after the cutoff

      await buildEngine([ExcessiveRefundsRule()]).runSweep();
      expect(await allFlags(), hasLength(1));
    });
  });
}
