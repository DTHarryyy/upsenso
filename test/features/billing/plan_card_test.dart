import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/widgets/plan_card.dart';

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
  featureFlags: {
    'crm': false,
    'procurement': false,
    'reports': 'basic',
    'audit': 'local',
  },
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
  featureFlags: {'crm': 'basic', 'reports': 'basic', 'audit': 'cloud'},
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
  maxDevices: null, // unlimited
  featureFlags: {
    'crm': 'full',
    'procurement': true,
    'reports': 'full',
    'audit': 'full',
  },
);

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

PlanCard _card(
  PlanOption plan, {
  PlanOption? previousTier,
  PlanOption? currentPlan,
  bool annual = false,
  bool isCurrent = false,
  bool isRecommended = false,
  bool leadWithEverything = false,
  bool canManage = true,
  bool busy = false,
  double? grandfatheredPrice,
  VoidCallback? onSelect,
}) =>
    PlanCard(
      plan: plan,
      previousTier: previousTier,
      currentPlan: currentPlan,
      annual: annual,
      isCurrent: isCurrent,
      isRecommended: isRecommended,
      leadWithEverything: leadWithEverything,
      busy: busy,
      canManage: canManage,
      grandfatheredPrice: grandfatheredPrice,
      onSelect: onSelect ?? () {},
    );

void main() {
  testWidgets('current card shows badge and a locked button', (tester) async {
    await tester.pumpWidget(_wrap(_card(_starter, isCurrent: true)));

    // Badge + button both read "Current plan".
    expect(find.text('Current plan'), findsWidgets);
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
    expect(find.text('Most Popular'), findsNothing);
  });

  testWidgets('recommended card shows Most Popular badge + filled CTA',
      (tester) async {
    await tester.pumpWidget(
        _wrap(_card(_starter, previousTier: _free, isRecommended: true)));
    expect(find.text('Most Popular'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('recommended + current falls back to current, not popular',
      (tester) async {
    await tester.pumpWidget(_wrap(
        _card(_starter, isRecommended: true, isCurrent: true, currentPlan: _starter)));
    expect(find.text('Most Popular'), findsNothing);
    expect(find.text('Current plan'), findsWidgets);
  });

  testWidgets('upgrade CTA names the plan (outlined tier)', (tester) async {
    await tester.pumpWidget(
        _wrap(_card(_growth, previousTier: _starter, currentPlan: _free)));
    expect(find.text('Upgrade to Growth'), findsOneWidget);
  });

  testWidgets('cheaper plan renders a Switch CTA', (tester) async {
    await tester.pumpWidget(
        _wrap(_card(_starter, previousTier: _free, currentPlan: _growth)));
    expect(find.text('Switch to Starter'), findsOneWidget);
  });

  testWidgets('free card shows a disabled Free forever button', (tester) async {
    await tester.pumpWidget(_wrap(_card(_free, currentPlan: _growth)));
    expect(find.text('Free forever'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('non-manager sees a disabled Owner only button', (tester) async {
    await tester.pumpWidget(
        _wrap(_card(_growth, previousTier: _starter, canManage: false)));
    expect(find.text('Owner only'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('top tier leads with "Everything in {prev}" and shows only adds',
      (tester) async {
    await tester.pumpWidget(_wrap(_card(_growth,
        previousTier: _starter, currentPlan: _free, leadWithEverything: true)));

    expect(find.text('Everything in Starter'), findsOneWidget);
    expect(find.text('Procurement & suppliers'), findsOneWidget);
    expect(find.text('5 branches'), findsOneWidget);
    expect(find.text('Unlimited devices'), findsOneWidget);
    // Audit deepens cloud → full, so it belongs in the delta with Growth's copy.
    expect(find.text('Audit log & unusual-activity alerts'), findsOneWidget);
    // Shared with Starter → covered by the "Everything in" line, not repeated.
    expect(find.text('Cloud backup & sync'), findsNothing);
    expect(find.text('Cloud-backed audit log'), findsNothing);
  });

  testWidgets('local audit is not sold as a feature row', (tester) async {
    await tester.pumpWidget(_wrap(_card(_free)));
    expect(find.textContaining('audit'), findsNothing);
    expect(find.textContaining('Audit'), findsNothing);
  });

  // Starter sells the log viewer; the unusual-activity alerts stay a Growth
  // line, so the two cards must not both advertise the same thing.
  testWidgets('starter card sells the audit log, not the alerts', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_card(_starter, previousTier: _free)));
    expect(find.text('Audit log'), findsOneWidget);
    expect(find.text('Audit log & unusual-activity alerts'), findsNothing);
    expect(find.text('3 devices'), findsOneWidget);
  });

  testWidgets('non-ladder card renders the full capability list',
      (tester) async {
    await tester.pumpWidget(_wrap(_card(_free)));

    expect(find.textContaining('Everything in'), findsNothing);
    expect(find.text('Works fully offline'), findsOneWidget);
    expect(find.text('1 device'), findsOneWidget);
    expect(find.text('1 branch'), findsOneWidget);
    expect(find.text('2 team members'), findsOneWidget);
  });

  testWidgets('free price shows ₱0 / forever', (tester) async {
    await tester.pumpWidget(_wrap(_card(_free)));
    expect(find.text('₱0'), findsOneWidget);
    expect(find.text('/forever'), findsOneWidget);
  });

  testWidgets('annual toggle shows yearly price', (tester) async {
    await tester.pumpWidget(
        _wrap(_card(_growth, previousTier: _starter, annual: true)));
    expect(find.text('₱4,990'), findsOneWidget);
    expect(find.text('/year'), findsOneWidget);
  });

  testWidgets('paid card states the daily equivalent under the price',
      (tester) async {
    await tester.pumpWidget(_wrap(_card(_starter, previousTier: _free)));
    expect(find.text('About ₱7 a day'), findsOneWidget);
  });

  testWidgets('free card has no per-day line', (tester) async {
    await tester.pumpWidget(_wrap(_card(_free)));
    expect(find.textContaining('a day'), findsNothing);
  });

  // Whether a lock is real depends on status and tier, which only the tab
  // knows — the card renders exactly what it is handed. Passing the raw
  // entitlement value here is what put a lapsed tenant's ₱499 on the Free card.
  testWidgets('locked-price chip renders whatever the caller validated',
      (tester) async {
    await tester.pumpWidget(
        _wrap(_card(_starter, isCurrent: true, grandfatheredPrice: 149)));
    expect(find.text('Your locked price · ₱149/mo'), findsOneWidget);

    await tester.pumpWidget(_wrap(_card(_starter, isCurrent: true)));
    expect(find.textContaining('locked price'), findsNothing);
  });

  testWidgets('the locked chip replaces the per-day line, never stacks on it',
      (tester) async {
    await tester.pumpWidget(
        _wrap(_card(_starter, isCurrent: true, grandfatheredPrice: 149)));
    expect(find.textContaining('a day'), findsNothing);
  });

  // Every row is a capability now. The grey dash rows the entry tier used to
  // append read as a crippled product rather than an honest one.
  testWidgets('no card renders an unchecked row', (tester) async {
    await tester.pumpWidget(_wrap(_card(_free)));

    expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsWidgets);
    expect(find.text('No cloud backup'), findsNothing);
  });

  // The disclosure the removed exclusions used to carry now rides on Free's
  // own capability row, so nobody reads the tier as backed up.
  testWidgets('free card still warns that nothing leaves the device', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_card(_free)));

    expect(
      find.text('Stays on this device — lose or reset it and the data goes '
          'with it'),
      findsOneWidget,
    );
  });

  testWidgets('capability rows carry a plain-language explanation',
      (tester) async {
    await tester.pumpWidget(_wrap(_card(_starter, previousTier: _free)));

    expect(
      find.text('Phones, tablets or computers signed in at the same time'),
      findsOneWidget,
    );
    expect(find.text('Staff accounts that can log in and sell'), findsOneWidget);
  });
}
