import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/features/billing/data/iap_service.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/widgets/current_plan_card.dart';

// Local fixtures on purpose: the sibling billing test files carry their own
// `_growth` with different featureFlags, and unifying them would silently
// change expectations over there.
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
  maxDevices: 10,
);

const _business = PlanOption(
  code: 'business',
  version: 1,
  name: 'Business',
  priceMonthly: 999,
  isActive: true,
  cloudEnabled: true,
  maxBranches: 20,
  maxSeats: 50,
);

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

CurrentPlanCard _card({
  String planCode = 'growth',
  String effectiveStatus = 'active',
  PlanOption? currentPlan,
  PlanOption? nextTier,
  double? lockedPrice,
  String? ownedProductId,
  bool playSupported = true,
  bool canManage = true,
  VoidCallback? onUpgrade,
}) => CurrentPlanCard(
  planCode: planCode,
  effectiveStatus: effectiveStatus,
  currentPlan: currentPlan,
  nextTier: nextTier,
  lockedPrice: lockedPrice,
  ownedProductId: ownedProductId,
  playSupported: playSupported,
  canManage: canManage,
  onUpgrade: onUpgrade ?? () {},
);

void main() {
  testWidgets('names the tier under an Account plan label', (tester) async {
    await tester.pumpWidget(_wrap(_card()));

    expect(find.text('ACCOUNT PLAN'), findsOneWidget);
    expect(find.text('Growth Plan'), findsOneWidget);
  });

  // Offline the catalog never loads, but the entitlement cache still knows the
  // tier — the card reads from planCode alone and never needs it.
  testWidgets('renders from the cached plan code with no catalog', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_card(planCode: 'starter')));

    expect(find.text('Starter Plan'), findsOneWidget);
  });

  // Price, renewal date, benefits and usage meters moved to the other tabs.
  // Once someone has bought, repeating them here is noise.
  testWidgets('carries no price, renewal date or usage meters', (tester) async {
    await tester.pumpWidget(_wrap(_card()));

    expect(find.textContaining('₱'), findsNothing);
    expect(find.textContaining('Renews'), findsNothing);
    expect(find.text('Branches'), findsNothing);
    expect(find.text('Cloud backup & sync'), findsNothing);
  });

  group('Manage subscription', () {
    testWidgets('offered to an owner on Android', (tester) async {
      await tester.pumpWidget(_wrap(_card()));
      expect(find.text('Manage subscription'), findsOneWidget);
    });

    testWidgets('past_due asks for the payment, not an upgrade', (tester) async {
      await tester.pumpWidget(_wrap(_card(effectiveStatus: 'past_due')));

      expect(find.text('Fix payment in Google Play'), findsOneWidget);
      expect(find.text('Manage subscription'), findsNothing);
    });

    testWidgets('hidden off Play, pointing at the Android app', (tester) async {
      await tester.pumpWidget(_wrap(_card(playSupported: false)));

      expect(find.text('Manage subscription'), findsNothing);
      expect(find.textContaining('Upsenso Android app'), findsOneWidget);
    });

    testWidgets('hidden without billing.manage', (tester) async {
      await tester.pumpWidget(_wrap(_card(canManage: false)));

      expect(find.text('Manage subscription'), findsNothing);
      expect(find.textContaining('Only the business owner'), findsOneWidget);
    });
  });

  group('upgrade nudge', () {
    testWidgets('names the next tier and wires the tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          _card(
            planCode: 'starter',
            currentPlan: _starter,
            nextTier: _growth,
            onUpgrade: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Get more with Growth'), findsOneWidget);
      // Copy is derived from the catalog, not written per tier.
      expect(find.textContaining('5 branches'), findsOneWidget);

      await tester.tap(find.text('Upgrade'));
      expect(tapped, isTrue);
    });

    // The nudge used to be hardcoded to Starter, stranding everyone above it.
    testWidgets('shown to a mid tier that still has room', (tester) async {
      await tester.pumpWidget(
        _wrap(_card(currentPlan: _growth, nextTier: _business)),
      );

      expect(find.text('Get more with Business'), findsOneWidget);
    });

    testWidgets('withheld on the top tier', (tester) async {
      await tester.pumpWidget(_wrap(_card(currentPlan: _business)));
      expect(find.text('Upgrade'), findsNothing);
    });

    // Offline the catalog never loads — and you couldn't buy anyway.
    testWidgets('withheld with no catalog', (tester) async {
      await tester.pumpWidget(_wrap(_card()));
      expect(find.text('Upgrade'), findsNothing);
    });

    // Pointing someone at a ladder they can't buy from is worse than silence.
    testWidgets('withheld when the tenant cannot buy', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _card(currentPlan: _starter, nextTier: _growth, canManage: false),
        ),
      );
      expect(find.text('Upgrade'), findsNothing);

      await tester.pumpWidget(
        _wrap(
          _card(currentPlan: _starter, nextTier: _growth, playSupported: false),
        ),
      );
      expect(find.text('Upgrade'), findsNothing);
    });
  });

  // The subscriber ladder used to be the only place this showed; losing it
  // would have silently retired a discount the tenant is entitled to see.
  group('locked price', () {
    testWidgets('a grandfathered tenant sees what they pay', (tester) async {
      await tester.pumpWidget(_wrap(_card(lockedPrice: 399)));

      expect(find.text('Your locked price · ₱399/mo'), findsOneWidget);
    });

    testWidgets('absent for everyone else', (tester) async {
      await tester.pumpWidget(_wrap(_card()));

      expect(find.textContaining('locked price'), findsNothing);
    });
  });

  group('manageSubscriptionUri', () {
    test('targets the exact subscription when the product is known', () {
      final uri = IapService.manageSubscriptionUri(
        productId: 'upsenso_growth_monthly',
      );

      expect(uri.queryParameters['sku'], 'upsenso_growth_monthly');
      expect(uri.queryParameters['package'], IapService.playPackageName);
    });

    test('falls back to the subscriptions list when it is not', () {
      final uri = IapService.manageSubscriptionUri();

      expect(uri.queryParameters, isEmpty);
      expect(uri.path, '/store/account/subscriptions');
    });
  });
}
