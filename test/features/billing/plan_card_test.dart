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
  featureFlags: {'crm': false, 'procurement': false, 'reports': 'basic'},
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
  maxDevices: 2,
  featureFlags: {'crm': 'basic', 'reports': 'basic', 'cloud_audit': true},
);

const _growth = PlanOption(
  code: 'growth',
  version: 1,
  name: 'Growth',
  priceMonthly: 499,
  isActive: true,
  cloudEnabled: true,
  maxBranches: 3,
  maxSeats: 10,
  maxDevices: 5,
  featureFlags: {
    'crm': 'full',
    'procurement': true,
    'reports': 'full',
    'cloud_audit': true,
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
    expect(find.text('3 branches'), findsOneWidget);
    // Shared with Starter → covered by the "Everything in" line, not repeated.
    expect(find.text('Cloud backup & sync'), findsNothing);
    expect(find.text('Cloud audit trail'), findsNothing);
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

  testWidgets('grandfathered price chip shows on the current card only',
      (tester) async {
    await tester.pumpWidget(
        _wrap(_card(_starter, isCurrent: true, grandfatheredPrice: 149)));
    expect(find.text('Price locked at ₱149/mo'), findsOneWidget);

    await tester.pumpWidget(_wrap(_card(_starter, grandfatheredPrice: 149)));
    expect(find.text('Price locked at ₱149/mo'), findsNothing);
  });
}
