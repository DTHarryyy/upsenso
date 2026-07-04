import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/audit/audit_chain_verifier.dart';
import 'package:pos/core/audit/audit_hash.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/device/device_identity_service.dart';
import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/audit_tamper_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/control_change_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/excessive_refunds_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/high_discount_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/orphaned_record_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/permission_probing_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/quick_refund_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/refund_structuring_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/shrinkage_spike_rule.dart';
import 'package:pos/core/services/fraud_rules/rules/time_reversal_rule.dart';

class MockDeviceIdentityService extends Mock implements DeviceIdentityService {}

void main() {
  late AppDatabase db;
  final now = DateTime.now();

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  FraudScanContext ctx({
    Duration window = const Duration(days: 30),
    DateTime? auditMirrorFreshAt,
  }) {
    return FraudScanContext(
      db: db,
      businessId: 'biz1',
      windowStart: now.subtract(window),
      now: now,
      ownerUserId: 'owner1',
      auditMirrorFreshAt: auditMirrorFreshAt,
    );
  }

  int unix(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  Future<void> seedRefund({
    required String id,
    String user = 'cash1',
    double amount = 100,
    DateTime? at,
    String? transactionId,
  }) {
    final t = unix(at ?? now);
    return db.customStatement(
      'INSERT INTO refunds (id, transaction_id, business_id, branch_id, '
      'refunded_by, total_amount, created_at, updated_at, client_updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [id, transactionId ?? 'tx-$id', 'biz1', 'br1', user, amount, t, t, t],
    );
  }

  Future<void> seedTransaction({
    required String id,
    String cashier = 'cash1',
    double subtotal = 100,
    double discount = 0,
    DateTime? at,
  }) {
    final t = unix(at ?? now);
    return db.customStatement(
      'INSERT INTO transactions (id, business_id, branch_id, cashier_id, '
      'total_amount, discount_amount, tax_amount, subtotal, item_count, '
      'created_at) VALUES (?, ?, ?, ?, ?, ?, 0, ?, 1, ?)',
      [id, 'biz1', 'br1', cashier, subtotal - discount, discount, subtotal, t],
    );
  }

  Future<void> seedAudit({
    required String id,
    required String actionType,
    String user = 'cash1',
    String metadata = '{}',
    String? entityId,
    DateTime? at,
    int? seq,
    String? deviceUid,
    String? entryHash,
    String? prevHash,
    String? syncError,
    int? hashVersion,
  }) {
    final t = unix(at ?? now);
    return db.customStatement(
      'INSERT INTO audit_logs (id, business_id, branch_id, user_id, '
      'action_type, entity_type, entity_id, description, metadata, device_id, '
      'created_at, seq, device_uid, entry_hash, prev_hash, sync_error, '
      'hash_version) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        id, 'biz1', 'br1', user, actionType, 'test', entityId, 'test',
        metadata, 'Device', t, seq, deviceUid, entryHash, prevHash, syncError,
        hashVersion,
      ],
    );
  }

  group('EXCESSIVE_REFUNDS', () {
    test('flags a count-floor breach with a deterministic dedupe key',
        () async {
      for (var i = 0; i < 6; i++) {
        await seedRefund(id: 'r$i', amount: 50);
      }
      final drafts = await ExcessiveRefundsRule().evaluate(ctx());
      expect(drafts, hasLength(1));
      expect(drafts.single.subjectUserId, 'cash1');
      expect(drafts.single.severity, FraudSeverity.high);

      // Re-running yields the SAME dedupe key — flags converge, not duplicate.
      final again = await ExcessiveRefundsRule().evaluate(ctx());
      expect(again.single.dedupeKey, drafts.single.dedupeKey);
    });

    test('stays quiet at the boundary (exactly the floor)', () async {
      for (var i = 0; i < 5; i++) {
        await seedRefund(id: 'r$i', amount: 50);
      }
      expect(await ExcessiveRefundsRule().evaluate(ctx()), isEmpty);
    });

    test('flags a value-floor breach even with one refund', () async {
      await seedRefund(id: 'big', amount: 6000);
      final drafts = await ExcessiveRefundsRule().evaluate(ctx());
      expect(drafts, hasLength(1));
    });
  });

  group('REFUND_STRUCTURING', () {
    Future<void> seedSettings({bool require = true, double threshold = 2000}) {
      return db.customStatement(
        'INSERT INTO refund_settings (id, business_id, require_approval, '
        'approval_threshold) VALUES (?, ?, ?, ?)',
        ['biz1', 'biz1', require ? 1 : 0, threshold],
      );
    }

    test('flags repeated refunds just under the approval threshold', () async {
      await seedSettings();
      await seedRefund(id: 's1', amount: 1900);
      await seedRefund(id: 's2', amount: 1850);
      await seedRefund(id: 's3', amount: 1500);
      final drafts = await RefundStructuringRule().evaluate(ctx());
      expect(drafts, hasLength(1));
      expect(drafts.single.severity, FraudSeverity.high);
      expect(drafts.single.relatedIds, isNot(isEmpty));
    });

    test('ignores refunds outside the band and disabled approval', () async {
      await seedSettings();
      await seedRefund(id: 'low1', amount: 500);
      await seedRefund(id: 'low2', amount: 600);
      await seedRefund(id: 'low3', amount: 700);
      expect(await RefundStructuringRule().evaluate(ctx()), isEmpty);

      await db.customStatement('DELETE FROM refund_settings');
      await seedSettings(require: false);
      await seedRefund(id: 's1', amount: 1900);
      await seedRefund(id: 's2', amount: 1850);
      await seedRefund(id: 's3', amount: 1800);
      expect(await RefundStructuringRule().evaluate(ctx()), isEmpty);
    });
  });

  group('QUICK_REFUND', () {
    test('flags a same-cashier refund minutes after the sale', () async {
      final saleAt = now.subtract(const Duration(minutes: 10));
      await seedTransaction(id: 'tx1', at: saleAt);
      await seedRefund(
        id: 'qr1',
        transactionId: 'tx1',
        at: saleAt.add(const Duration(minutes: 5)),
      );
      final drafts = await QuickRefundRule().evaluate(ctx());
      expect(drafts, hasLength(1));
      expect(drafts.single.severity, FraudSeverity.medium);
    });

    test('not restocked boosts severity to high', () async {
      final saleAt = now.subtract(const Duration(minutes: 10));
      await seedTransaction(id: 'tx1', at: saleAt);
      await seedRefund(
        id: 'qr1',
        transactionId: 'tx1',
        at: saleAt.add(const Duration(minutes: 5)),
      );
      await db.customStatement(
        'INSERT INTO refund_items (id, refund_id, transaction_item_id, '
        'variant_id, qty, amount, restocked) VALUES '
        "('ri1', 'qr1', 'ti1', 'v1', 1, 100, 0)",
      );
      final drafts = await QuickRefundRule().evaluate(ctx());
      expect(drafts.single.severity, FraudSeverity.high);
    });

    test('a different refunder is not a quick-refund pattern', () async {
      final saleAt = now.subtract(const Duration(minutes: 10));
      await seedTransaction(id: 'tx1', cashier: 'cash1', at: saleAt);
      await seedRefund(
        id: 'qr1',
        transactionId: 'tx1',
        user: 'manager1',
        at: saleAt.add(const Duration(minutes: 5)),
      );
      expect(await QuickRefundRule().evaluate(ctx()), isEmpty);
    });
  });

  group('HIGH_DISCOUNT', () {
    test('boundary: exactly 30% does not flag, above does', () async {
      await seedTransaction(id: 'ok', subtotal: 100, discount: 30);
      expect(await HighDiscountRule().evaluate(ctx()), isEmpty);

      await seedTransaction(id: 'heavy', subtotal: 100, discount: 31);
      final drafts = await HighDiscountRule().evaluate(ctx());
      expect(drafts, hasLength(1));
      expect(drafts.single.dedupeKey, 'HIGH_DISCOUNT|heavy');
    });
  });

  group('SHRINKAGE_SPIKE', () {
    Future<void> seedWriteOff({
      required String id,
      required double qty,
      DateTime? at,
    }) async {
      await db.customStatement(
        'INSERT INTO stock_ledger (id, variant_id, product_id, branch_id, '
        "business_id, change_type, quantity, reason, created_at) VALUES "
        "(?, 'v1', 'p1', 'br1', 'biz1', 'OUT', ?, 'Damage', ?)",
        [id, qty, unix(at ?? now)],
      );
    }

    setUp(() async {
      await db.customStatement(
        "INSERT INTO product_variants (id, product_id, business_id, name, "
        "cost_price) VALUES ('v1', 'p1', 'biz1', 'Default', 100)",
      );
    });

    test('flags a cost-weighted write-off over the floor', () async {
      await seedWriteOff(id: 'w1', qty: 40); // 40 × ₱100 = ₱4,000 > ₱3,000
      final drafts = await ShrinkageSpikeRule().evaluate(ctx());
      expect(drafts, hasLength(1));
      expect(drafts.single.branchId, 'br1');
    });

    test('small write-offs stay quiet', () async {
      await seedWriteOff(id: 'w1', qty: 10); // ₱1,000
      expect(await ShrinkageSpikeRule().evaluate(ctx()), isEmpty);
    });
  });

  group('TIME_REVERSAL', () {
    test('flags a clock rollback between adjacent chain entries', () async {
      await seedAudit(
        id: 'a1',
        actionType: 'SALE_CREATED',
        seq: 1,
        deviceUid: 'dev1',
        at: now.subtract(const Duration(minutes: 10)),
      );
      await seedAudit(
        id: 'a2',
        actionType: 'SALE_CREATED',
        seq: 2,
        deviceUid: 'dev1',
        at: now.subtract(const Duration(minutes: 40)), // 30 min BEFORE seq 1
      );
      final drafts = await TimeReversalRule().evaluate(ctx());
      expect(drafts, hasLength(1));
      expect(drafts.single.dedupeKey, 'TIME_REVERSAL|dev1|2');
    });

    test('forward time and small drift are fine', () async {
      await seedAudit(
        id: 'a1',
        actionType: 'SALE_CREATED',
        seq: 1,
        deviceUid: 'dev1',
        at: now.subtract(const Duration(minutes: 10)),
      );
      await seedAudit(
        id: 'a2',
        actionType: 'SALE_CREATED',
        seq: 2,
        deviceUid: 'dev1',
        at: now.subtract(const Duration(minutes: 11)), // within tolerance
      );
      expect(await TimeReversalRule().evaluate(ctx()), isEmpty);
    });
  });

  group('PERMISSION_PROBING', () {
    test('flags many denials across distinct permissions', () async {
      for (var i = 0; i < 6; i++) {
        await seedAudit(
          id: 'd$i',
          actionType: 'PERMISSION_DENIED',
          metadata: '{"permission":"perm_${i % 4}"}',
        );
      }
      final drafts = await PermissionProbingRule().evaluate(ctx());
      expect(drafts, hasLength(1));
      expect(drafts.single.severity, FraudSeverity.medium);
    });

    test('hitting the same wall repeatedly is not recon', () async {
      for (var i = 0; i < 8; i++) {
        await seedAudit(
          id: 'd$i',
          actionType: 'PERMISSION_DENIED',
          metadata: '{"permission":"pos.refund_sale"}',
        );
      }
      expect(await PermissionProbingRule().evaluate(ctx()), isEmpty);
    });
  });

  group('CONTROL_CHANGE', () {
    test('flags the audit module being switched off, not on', () async {
      await seedAudit(
        id: 'm1',
        actionType: 'BUSINESS_MODULE_CHANGED',
        metadata: '{"module":"audit","enabled":false}',
      );
      await seedAudit(
        id: 'm2',
        actionType: 'BUSINESS_MODULE_CHANGED',
        metadata: '{"module":"audit","enabled":true}',
      );
      final drafts = await ControlChangeRule().evaluate(ctx());
      expect(drafts, hasLength(1));
      expect(drafts.single.relatedIds, ['m1']);
    });

    test('flags a raised refund threshold and a sensitive override grant',
        () async {
      await seedAudit(
        id: 't1',
        actionType: 'REFUND_SETTINGS_CHANGED',
        metadata: '{"require_approval":true,"require_approval_before":true,'
            '"threshold":5000.0,"threshold_before":2000.0}',
      );
      await seedAudit(
        id: 'o1',
        actionType: 'PERMISSION_OVERRIDE_SET',
        entityId: 'emp-1',
        metadata: '{"permission_code":"pos.approve_refund","granted":true}',
      );
      final drafts = await ControlChangeRule().evaluate(ctx());
      expect(drafts, hasLength(2));
    });

    test('a burst of sensitive override grants collapses into one digest flag',
        () async {
      // The 2026-07-03 shape: many override rows by one actor in one burst.
      const keys = [
        'pos.approve_refund',
        'audit_logs.view',
        'settings.edit_business',
      ];
      for (var i = 0; i < keys.length; i++) {
        await seedAudit(
          id: 'o$i',
          actionType: 'PERMISSION_OVERRIDE_SET',
          entityId: 'emp-1',
          metadata: '{"permission_code":"${keys[i]}","granted":true}',
        );
      }
      final drafts = await ControlChangeRule().evaluate(ctx());
      expect(drafts, hasLength(1), reason: 'one digest, not one flag per key');
      expect(drafts.single.dedupeKey, startsWith('CONTROL_CHANGE|override|'));
      expect(drafts.single.relatedIds, hasLength(3));
      expect(drafts.single.description, contains('3 sensitive permission'));
    });

    test('a lowered threshold is a tightening — no flag', () async {
      await seedAudit(
        id: 't1',
        actionType: 'REFUND_SETTINGS_CHANGED',
        metadata: '{"require_approval":true,"require_approval_before":true,'
            '"threshold":1000.0,"threshold_before":2000.0}',
      );
      expect(await ControlChangeRule().evaluate(ctx()), isEmpty);
    });
  });

  group('ORPHANED_RECORD', () {
    test('flags a refund with no audit entry, after the grace lag', () async {
      // Chain era started yesterday.
      await seedAudit(
        id: 'genesis',
        actionType: 'SALE_CREATED',
        seq: 1,
        deviceUid: 'dev1',
        at: now.subtract(const Duration(days: 1)),
      );
      // Audited refund — has a matching entry.
      await seedRefund(
        id: 'audited',
        at: now.subtract(const Duration(hours: 2)),
      );
      await seedAudit(
        id: 'ar1',
        actionType: 'REFUND_CREATED',
        entityId: 'audited',
        at: now.subtract(const Duration(hours: 2)),
      );
      // Orphan — written straight into the DB, no audit trail.
      await seedRefund(
        id: 'orphan',
        at: now.subtract(const Duration(hours: 1)),
      );
      // Fresh — inside the grace lag, audit may still be in flight.
      await seedRefund(id: 'fresh', at: now);

      // Mirror is current (pulled up to now) — the freshness gate is satisfied,
      // so a records-vs-audit mismatch is trustworthy.
      final drafts =
          await OrphanedRecordRule().evaluate(ctx(auditMirrorFreshAt: now));
      expect(drafts, hasLength(1));
      expect(drafts.single.dedupeKey, 'ORPHANED_RECORD|orphan');
      expect(drafts.single.severity, FraudSeverity.high);
    });

    test('a stale/never-pulled mirror suppresses orphan flags', () async {
      await seedAudit(
        id: 'genesis',
        actionType: 'SALE_CREATED',
        seq: 1,
        deviceUid: 'dev1',
        at: now.subtract(const Duration(days: 1)),
      );
      await seedRefund(id: 'orphan', at: now.subtract(const Duration(hours: 1)));
      // No watermark → the mirror was never pulled → cannot judge absence.
      expect(await OrphanedRecordRule().evaluate(ctx()), isEmpty);
    });

    test('pre-chain records are exempt', () async {
      // No chained audit rows at all → chain era hasn't started.
      await seedRefund(id: 'old', at: now.subtract(const Duration(hours: 3)));
      expect(
        await OrphanedRecordRule().evaluate(ctx(auditMirrorFreshAt: now)),
        isEmpty,
      );
      expect(OrphanedRecordRule().requiresFullAuditMirror, isTrue);
    });
  });

  group('AUDIT_TAMPER', () {
    AuditTamperRule buildRule() {
      final deviceIdentity = MockDeviceIdentityService();
      when(() => deviceIdentity.getDeviceUid()).thenAnswer((_) async => 'dev1');
      return AuditTamperRule(
        verifier: AuditChainVerifier(
          dao: AuditLogsDao(db),
          deviceIdentityService: deviceIdentity,
        ),
      );
    }

    test('a verifier break (altered row) raises a critical flag', () async {
      // A chained row whose stored hash does not recompute → hashMismatch.
      await seedAudit(
        id: 'g1',
        actionType: 'SALE_CREATED',
        seq: 1,
        deviceUid: 'dev1',
        prevHash: kAuditGenesisHash,
        entryHash: 'bogus-not-the-real-hash',
        hashVersion: kAuditHashVersion, // v2 rows get the full hash recompute
      );
      final drafts = await buildRule().evaluate(ctx());
      expect(drafts, hasLength(1));
      expect(drafts.single.severity, FraudSeverity.critical);
      expect(drafts.single.ruleCode, 'AUDIT_TAMPER');
    });

    test('a benign push conflict (CHAIN_CONFLICT sync_error, valid chain) no '
        'longer raises a flag', () async {
      // A VALID genesis row (its hash recomputes) that also carries a
      // CHAIN_CONFLICT marker — the exact 2026-07-03 false-positive shape.
      final storedAt = DateTime.fromMillisecondsSinceEpoch(
        (now.millisecondsSinceEpoch ~/ 1000) * 1000,
      );
      final payload = canonicalAuditPayload(
        actionType: 'SALE_CREATED',
        branchId: 'br1',
        businessId: 'biz1',
        createdAt: storedAt,
        description: 'test',
        deviceUid: 'dev1',
        entityId: null,
        entityType: 'test',
        metadataJson: '{}',
        seq: 1,
        userId: 'cash1',
      );
      final validHash =
          auditEntryHash(prevHash: kAuditGenesisHash, canonicalPayload: payload);
      await seedAudit(
        id: 'c1',
        actionType: 'SALE_CREATED',
        seq: 1,
        deviceUid: 'dev1',
        prevHash: kAuditGenesisHash,
        entryHash: validHash,
        at: storedAt,
        syncError: 'AuditChainConflictException(c1): CHAIN_CONFLICT dup',
        hashVersion: kAuditHashVersion,
      );
      expect(await buildRule().evaluate(ctx()), isEmpty);
    });
  });
}
