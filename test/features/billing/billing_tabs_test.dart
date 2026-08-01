import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';
import 'package:pos/features/billing/presentation/tabs/billing_devices_tab.dart';
import 'package:pos/features/billing/presentation/tabs/billing_history_tab.dart';
import 'package:pos/features/billing/presentation/tabs/billing_plans_tab.dart';
import 'package:pos/features/billing/presentation/tabs/billing_usage_tab.dart';
import 'package:pos/features/billing/presentation/widgets/plan_cards_skeleton.dart';

class MockBillingCubit extends MockCubit<BillingState> implements BillingCubit {}

class MockPermissionService extends Mock implements PermissionService {}

class MockEnforcement extends Mock implements EntitlementEnforcementService {}

const _freePlanState = BillingState(
  status: BillingStatus.ready,
  planCode: 'free',
  effectiveStatus: 'free',
  maxBranches: 1,
  maxSeats: 2,
  maxDevices: 1,
);

final _device = RegisteredDevice(
  deviceUid: 'device-1',
  label: 'Pixel 7',
  platform: 'android',
  lastSeenAt: DateTime(2026, 7, 31),
);

const _free = PlanOption(
  code: 'free',
  version: 1,
  name: 'Free',
  priceMonthly: 0,
  isActive: true,
  cloudEnabled: false,
  maxBranches: 1,
  maxSeats: 2,
  maxDevices: 1,
);

const _starter = PlanOption(
  code: 'starter',
  version: 1,
  name: 'Starter',
  priceMonthly: 199,
  isActive: true,
  cloudEnabled: true,
  maxBranches: 1,
  maxSeats: 3,
  maxDevices: 3,
);

const _growth = PlanOption(
  code: 'growth',
  version: 1,
  name: 'Growth',
  priceMonthly: 499,
  isActive: true,
  cloudEnabled: true,
  maxBranches: 5,
  maxSeats: 15,
  featureFlags: {'crm': 'full', 'procurement': true, 'reports': 'full'},
);

/// A paying Growth tenant, which is what collapses the ladder to a summary.
final _subscribedState = BillingState(
  status: BillingStatus.ready,
  planCode: 'growth',
  effectiveStatus: 'active',
  cloudEnabled: true,
  billingPeriod: 'monthly',
  renewsOn: DateTime(2026, 9, 14),
  plans: const [_free, _starter, _growth],
  playSupported: true,
  maxBranches: 5,
  maxSeats: 15,
);

final _payment = BillingPayment(
  id: 'pay-1',
  kind: 'plan',
  amount: 499,
  currency: 'PHP',
  status: 'paid',
  isTest: false,
  createdAt: DateTime(2026, 7, 1),
  planCode: 'growth',
);

void main() {
  late MockBillingCubit cubit;
  late MockPermissionService perms;

  setUp(() async {
    await sl.reset();
    cubit = MockBillingCubit();
    perms = MockPermissionService();
    sl.registerSingleton<PermissionService>(perms);
    // The usage tab reads the over-cap lock set directly. Default: nothing
    // locked, so these tests keep asserting the plain meters.
    final enforcement = MockEnforcement();
    when(() => enforcement.lockRevision).thenReturn(ValueNotifier<int>(0));
    when(() => enforcement.hasOverCapResources).thenReturn(false);
    when(() => enforcement.lockedBranchIds).thenReturn(const {});
    when(() => enforcement.suspendedEmployeeIds).thenReturn(const {});
    sl.registerSingleton<EntitlementEnforcementService>(enforcement);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pump(WidgetTester tester, BillingState state, Widget tab) async {
    whenListen(cubit, Stream<BillingState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<BillingCubit>.value(value: cubit, child: tab),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('BillingPlansTab', () {
    testWidgets('a paying tenant sees a summary, not the plan ladder', (
      tester,
    ) async {
      when(() => perms.can(any())).thenReturn(true);
      await pump(tester, _subscribedState, const BillingPlansTab());

      expect(find.text('Growth Plan'), findsOneWidget);
      expect(find.text('Manage subscription'), findsOneWidget);
      // The ladder's own affordances must be gone, not merely scrolled away.
      expect(find.text('Bill annually'), findsNothing);
      expect(find.text('Upgrade to Growth'), findsNothing);
      expect(find.text('Free forever'), findsNothing);
      // Growth is the top tier in this catalog — nothing to nudge toward.
      expect(find.text('Upgrade'), findsNothing);
    });

    // The nudge is a subscriber's only route to the ladder, and it must lead
    // to tiers above them rather than the whole catalog.
    testWidgets('the nudge opens a sheet of higher tiers only', (tester) async {
      when(() => perms.can(any())).thenReturn(true);
      final state = _subscribedState.copyWith(planCode: 'starter');
      await pump(tester, state, const BillingPlansTab());

      await tester.tap(find.text('Upgrade'));
      await tester.pumpAndSettle();

      expect(find.text('Growth'), findsOneWidget);
      expect(find.text('Everything in Starter'), findsOneWidget);
      // Exact match: the card behind reads "Starter Plan", so this genuinely
      // proves the tenant's own tier isn't offered back to them.
      expect(find.text('Starter'), findsNothing);
      expect(find.text('Free forever'), findsNothing);
      expect(find.text('Bill annually'), findsOneWidget);
    });

    testWidgets('past_due still counts as subscribed', (tester) async {
      when(() => perms.can(any())).thenReturn(true);
      final state = BillingState(
        status: BillingStatus.ready,
        planCode: 'growth',
        effectiveStatus: 'past_due',
        plans: const [_free, _starter, _growth],
        playSupported: true,
      );
      await pump(tester, state, const BillingPlansTab());

      // The summary, not the ladder — and the CTA names the actual problem.
      expect(find.text('Fix payment in Google Play'), findsOneWidget);
      expect(find.text('Bill annually'), findsNothing);
    });

    testWidgets('a free tenant still sees the full ladder', (tester) async {
      when(() => perms.can(any())).thenReturn(true);
      const state = BillingState(
        status: BillingStatus.ready,
        planCode: 'free',
        effectiveStatus: 'free',
        plans: [_free, _starter, _growth],
        playSupported: true,
      );
      await pump(tester, state, const BillingPlansTab());

      expect(find.text('Bill annually'), findsOneWidget);
      // Free is theirs, so it carries the current-plan treatment.
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Current plan'), findsWidgets);
      // Starter is the recommended tier, whose filled CTA carries a trailing →.
      expect(find.textContaining('Upgrade to Starter'), findsOneWidget);
      expect(find.text('Manage subscription'), findsNothing);
    });

    // Both were removed: restore now runs by itself, and the probe reports on
    // OUR server config, which a shop owner can neither read nor act on.
    testWidgets('no Restore purchases or Check billing setup buttons', (
      tester,
    ) async {
      when(() => perms.can(any())).thenReturn(true);
      const state = BillingState(
        status: BillingStatus.ready,
        planCode: 'free',
        effectiveStatus: 'free',
        plans: [_free, _starter, _growth],
        playSupported: true,
      );
      await pump(tester, state, const BillingPlansTab());

      expect(find.text('Restore purchases'), findsNothing);
      expect(find.text('Check billing setup'), findsNothing);
    });

    testWidgets('an automatic restore says so instead of running silently', (
      tester,
    ) async {
      when(() => perms.can(any())).thenReturn(true);
      const state = BillingState(
        status: BillingStatus.ready,
        planCode: 'free',
        effectiveStatus: 'free',
        plans: [_free, _starter, _growth],
        playSupported: true,
        restoreInProgress: true,
      );
      await pump(tester, state, const BillingPlansTab());

      expect(find.text('Checking your Google Play purchases…'), findsOneWidget);
    });

    // The bug: grandfathered_price outlives the subscription, so a lapsed
    // Growth tenant's ₱499 was rendered on the Free card they'd fallen back to.
    testWidgets('a lapsed tenant sees no locked price on Free', (tester) async {
      when(() => perms.can(any())).thenReturn(true);
      const state = BillingState(
        status: BillingStatus.ready,
        planCode: 'growth',
        effectiveStatus: 'lapsed',
        grandfatheredPrice: 499,
        plans: [_free, _starter, _growth],
        playSupported: true,
      );
      await pump(tester, state, const BillingPlansTab());

      expect(find.textContaining('locked price'), findsNothing);
    });

    testWidgets('a locked price equal to list price is not a lock', (
      tester,
    ) async {
      when(() => perms.can(any())).thenReturn(true);
      final state = _subscribedState.copyWith(grandfatheredPrice: 499);
      await pump(tester, state, const BillingPlansTab());

      expect(find.textContaining('locked price'), findsNothing);
    });

    // Its home is the Account plan card now — the subscriber ladder that used
    // to carry it is gone.
    testWidgets('a genuinely locked price is shown on the summary', (
      tester,
    ) async {
      when(() => perms.can(any())).thenReturn(true);
      final state = _subscribedState.copyWith(
        planCode: 'starter',
        grandfatheredPrice: 149,
      );
      await pump(tester, state, const BillingPlansTab());

      expect(find.text('Your locked price · ₱149/mo'), findsOneWidget);
    });

    testWidgets('plans load as skeleton cards, not a notice', (tester) async {
      when(() => perms.can(any())).thenReturn(true);
      const state = BillingState(
        status: BillingStatus.ready,
        planCode: 'free',
        effectiveStatus: 'free',
        playSupported: true,
      );
      whenListen(cubit, Stream<BillingState>.empty(), initialState: state);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<BillingCubit>.value(
              value: cubit,
              child: const BillingPlansTab(),
            ),
          ),
        ),
      );
      // No pumpAndSettle: the shimmer runs on a repeating controller.
      await tester.pump();

      expect(find.byType(PlanCardsSkeleton), findsOneWidget);
      expect(find.text('Loading plans…'), findsNothing);
      // The chrome stays put, so the real cards land without a jump.
      expect(find.text('Bill annually'), findsOneWidget);
    });
  });

  group('BillingUsageTab', () {
    testWidgets('shows meters on Free plan — caps are real there too', (
      tester,
    ) async {
      await pump(tester, _freePlanState, const BillingUsageTab());

      expect(find.text('Branches'), findsOneWidget);
      expect(find.text('Team members'), findsOneWidget);
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('No limits to show'), findsNothing);
    });

    testWidgets('shows an empty state when no cap is known', (tester) async {
      const state = BillingState(status: BillingStatus.ready);
      await pump(tester, state, const BillingUsageTab());

      expect(find.text('No limits to show'), findsOneWidget);
      expect(find.text('Branches'), findsNothing);
    });
  });

  group('BillingDevicesTab', () {
    testWidgets('offline shows the connection state, not "no devices"', (
      tester,
    ) async {
      when(() => perms.can(any())).thenReturn(false);
      const state = BillingState(status: BillingStatus.ready, offline: true);
      await pump(tester, state, const BillingDevicesTab());

      expect(find.text('Needs a connection'), findsOneWidget);
      expect(find.text('No devices registered yet'), findsNothing);
    });

    testWidgets('online with no devices shows the genuine empty state', (
      tester,
    ) async {
      when(() => perms.can(any())).thenReturn(false);
      const state = BillingState(status: BillingStatus.ready);
      await pump(tester, state, const BillingDevicesTab());

      expect(find.text('No devices registered yet'), findsOneWidget);
    });

    testWidgets('Revoke is hidden without billing.manage', (tester) async {
      when(() => perms.can(any())).thenReturn(false);
      final state = BillingState(status: BillingStatus.ready, devices: [_device]);
      await pump(tester, state, const BillingDevicesTab());

      expect(find.text('Pixel 7'), findsOneWidget);
      expect(find.text('Revoke'), findsNothing);
    });

    testWidgets('Revoke shows with billing.manage', (tester) async {
      when(() => perms.can(PermissionKeys.billingManage)).thenReturn(true);
      final state = BillingState(status: BillingStatus.ready, devices: [_device]);
      await pump(tester, state, const BillingDevicesTab());

      expect(find.text('Revoke'), findsOneWidget);
    });
  });

  group('BillingHistoryTab', () {
    testWidgets('offline shows the connection state, not "no payments"', (
      tester,
    ) async {
      const state = BillingState(status: BillingStatus.ready, offline: true);
      await pump(tester, state, BillingHistoryTab(onSeePlans: () {}));

      expect(find.text('Needs a connection'), findsOneWidget);
      expect(find.text('No payments yet'), findsNothing);
    });

    testWidgets('online with no payments on Free offers a See plans CTA', (
      tester,
    ) async {
      const state = BillingState(status: BillingStatus.ready, planCode: 'free');
      var tapped = false;
      await pump(
        tester,
        state,
        BillingHistoryTab(onSeePlans: () => tapped = true),
      );

      expect(find.text('No payments yet'), findsOneWidget);
      await tester.tap(find.text('See plans'));
      expect(tapped, isTrue);
    });

    testWidgets('renders payment rows when present', (tester) async {
      final state = BillingState(status: BillingStatus.ready, payments: [_payment]);
      await pump(tester, state, BillingHistoryTab(onSeePlans: () {}));

      expect(find.text('Plan: Growth'), findsOneWidget);
      expect(find.text('₱499'), findsOneWidget);
    });
  });
}
