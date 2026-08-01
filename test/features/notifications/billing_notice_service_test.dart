import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/features/notifications/data/billing_notice_ack.dart';
import 'package:pos/features/notifications/domain/billing_notice_service.dart';
import 'package:pos/features/notifications/domain/entities/billing_notice.dart';

class _MockEntitlement extends Mock implements EntitlementService {}

const _biz = 'biz-1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockEntitlement entitlement;
  late ValueNotifier<int> revision;

  setUp(() {
    entitlement = _MockEntitlement();
    revision = ValueNotifier<int>(0);
    when(() => entitlement.entitlementRevision).thenReturn(revision);
  });

  tearDown(() => revision.dispose());

  /// Builds a service over a fresh prefs store seeded with [prefs].
  Future<BillingNoticeService> build({
    required String status,
    int? days,
    Map<String, Object> prefs = const {},
  }) async {
    when(() => entitlement.effectiveStatus).thenReturn(status);
    when(() => entitlement.daysRemaining).thenReturn(days);
    SharedPreferences.setMockInitialValues(prefs);
    final store = await SharedPreferences.getInstance();
    return BillingNoticeService(entitlement, BillingNoticeAck(store));
  }

  group('which notice is due', () {
    test('past_due and lapsed each map to their own kind', () async {
      final pastDue = await build(status: 'past_due', days: 3);
      expect(pastDue.visibleKind(_biz), BillingNoticeKind.pastDue);

      final lapsed = await build(status: 'lapsed');
      expect(lapsed.visibleKind(_biz), BillingNoticeKind.lapsed);
    });

    test('a healthy account is told nothing', () async {
      final active = await build(status: 'active', days: 20);
      expect(active.visibleKind(_biz), isNull);

      final free = await build(status: 'free');
      expect(free.visibleKind(_biz), isNull);
    });

    // A month-long trial must not park a permanent unread badge on the bell
    // from day one — it only speaks up once it's worth acting on.
    test('a trial stays quiet until its last week', () async {
      final early = await build(status: 'trialing', days: 20);
      expect(early.visibleKind(_biz), isNull);

      final ending = await build(status: 'trialing', days: 7);
      expect(ending.visibleKind(_biz), BillingNoticeKind.trialing);

      final lastDay = await build(status: 'trialing', days: 0);
      expect(lastDay.visibleKind(_biz), BillingNoticeKind.trialing);
    });

    test('a trial with no end date to count down to says nothing', () async {
      final unknown = await build(status: 'trialing');
      expect(unknown.visibleKind(_biz), isNull);
    });
  });

  group('acknowledge', () {
    test('hides the notice and bumps the revision for the badge', () async {
      final service = await build(status: 'lapsed');
      var bumps = 0;
      service.revision.addListener(() => bumps++);

      await service.acknowledge(BillingNoticeKind.lapsed, _biz);

      expect(service.visibleKind(_biz), isNull);
      expect(bumps, 1);
    });

    test('is scoped per business', () async {
      final service = await build(status: 'lapsed');
      await service.acknowledge(BillingNoticeKind.lapsed, _biz);

      expect(service.visibleKind('biz-2'), BillingNoticeKind.lapsed);
    });

    // Dismissing "your trial is ending" must not also swallow the past-due
    // notice that arrives weeks later.
    test('does not pre-dismiss a different kind', () async {
      final trial = await build(status: 'trialing', days: 2);
      await trial.acknowledge(BillingNoticeKind.trialing, _biz);
      expect(trial.visibleKind(_biz), isNull);

      when(() => entitlement.effectiveStatus).thenReturn('past_due');
      when(() => entitlement.daysRemaining).thenReturn(5);
      expect(trial.visibleKind(_biz), BillingNoticeKind.pastDue);
    });
  });

  group('reArm', () {
    test('clears the acks of kinds that are no longer due', () async {
      final service = await build(status: 'trialing', days: 2);
      await service.acknowledge(BillingNoticeKind.trialing, _biz);

      // Trial ended and the card failed — the trial ack must not survive.
      when(() => entitlement.effectiveStatus).thenReturn('past_due');
      when(() => entitlement.daysRemaining).thenReturn(5);
      await service.reArm(_biz);

      when(() => entitlement.effectiveStatus).thenReturn('trialing');
      when(() => entitlement.daysRemaining).thenReturn(2);
      expect(service.visibleKind(_biz), BillingNoticeKind.trialing);
    });

    test('leaves the currently-due kind dismissed', () async {
      final service = await build(status: 'lapsed');
      await service.acknowledge(BillingNoticeKind.lapsed, _biz);

      await service.reArm(_biz);

      expect(service.visibleKind(_biz), isNull);
    });
  });

  // Merchants who dismissed the notice before it was generalised must not see
  // it resurrect, and the bell must not tick up, after this upgrade.
  group('legacy cloud_paused_ack key', () {
    test('still reads as dismissed for the lapsed notice', () async {
      final service = await build(
        status: 'lapsed',
        prefs: {'cloud_paused_ack:$_biz': true},
      );

      expect(service.visibleKind(_biz), isNull);
    });

    test('is cleared on re-arm so a future lapse speaks up again', () async {
      final service = await build(
        status: 'active',
        days: 30,
        prefs: {'cloud_paused_ack:$_biz': true},
      );

      await service.reArm(_biz);

      when(() => entitlement.effectiveStatus).thenReturn('lapsed');
      when(() => entitlement.daysRemaining).thenReturn(null);
      expect(service.visibleKind(_biz), BillingNoticeKind.lapsed);
    });
  });

  group('synthetic item', () {
    test('carries the reference the tile reads its variant from', () async {
      final service = await build(status: 'past_due', days: 1);
      final item = service.build(_biz)!;

      expect(billingNoticeKindOf(item), BillingNoticeKind.pastDue);
      expect(BillingNoticeService.isSyntheticId(item.id), isTrue);
      expect(item.isRead, isFalse);
      expect(item.body, contains('1 more day'));
    });

    test('is stable across rebuilds so the list does not churn', () async {
      final service = await build(status: 'lapsed');

      expect(service.build(_biz), equals(service.build(_biz)));
    });

    test('is null when nothing is due', () async {
      final service = await build(status: 'active', days: 12);
      expect(service.build(_biz), isNull);
    });
  });

  test('a real notification id is never mistaken for a synthetic one', () {
    expect(
      BillingNoticeService.isSyntheticId('3f2b1c9e-0000-4a11-9c3d-abcdef123456'),
      isFalse,
    );
  });
}
