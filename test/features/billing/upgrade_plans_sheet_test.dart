import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';
import 'package:pos/features/billing/presentation/widgets/plan_cards_skeleton.dart';
import 'package:pos/features/billing/presentation/widgets/upgrade_plans_sheet.dart';

class MockBillingCubit extends MockCubit<BillingState> implements BillingCubit {}

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

const _catalog = [_free, _starter, _growth, _business];

void main() {
  late MockBillingCubit cubit;

  setUp(() => cubit = MockBillingCubit());

  Future<void> pump(
    WidgetTester tester,
    BillingState state, {
    PlanOption current = _starter,
    bool canManage = true,
    // The skeleton shimmers on a repeating controller, so pumpAndSettle would
    // never return once placeholders are on screen.
    bool settle = true,
  }) async {
    whenListen(cubit, Stream<BillingState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<BillingCubit>.value(
            value: cubit,
            child: UpgradePlansSheet(
              currentPlan: current,
              annual: false,
              canManage: canManage,
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  const ready = BillingState(
    status: BillingStatus.ready,
    planCode: 'starter',
    effectiveStatus: 'active',
    plans: _catalog,
    playSupported: true,
  );

  // The whole point of the sheet: someone who has bought is asking what's
  // above them, not to re-read the tier they already hold.
  testWidgets('lists only tiers above the current one', (tester) async {
    await pump(tester, ready);

    expect(find.text('Growth'), findsOneWidget);
    expect(find.text('Business'), findsOneWidget);
    expect(find.text('Starter'), findsNothing);
    expect(find.text('Free'), findsNothing);
    expect(find.text('Free forever'), findsNothing);
  });

  testWidgets('leads the first card with the tenant\'s own tier', (
    tester,
  ) async {
    await pump(tester, ready);

    expect(find.text('Everything in Starter'), findsOneWidget);
  });

  testWidgets('every card sells an upgrade, none is marked current', (
    tester,
  ) async {
    await pump(tester, ready);

    // The spotlit card appends an arrow to its label, hence textContaining.
    expect(find.textContaining('Upgrade to Growth'), findsOneWidget);
    expect(find.textContaining('Upgrade to Business'), findsOneWidget);
    expect(find.text('Current plan'), findsNothing);
  });

  testWidgets('the period toggle switches the prices to yearly', (
    tester,
  ) async {
    await pump(tester, ready);
    expect(find.text('/month'), findsWidgets);

    await tester.tap(find.text('Bill annually'));
    await tester.pumpAndSettle();

    expect(find.text('/year'), findsWidgets);
    expect(find.text('/month'), findsNothing);
  });

  // Purchase errors surface as snackbars on the page behind, which would be
  // hidden by a still-open modal.
  testWidgets('selecting a tier closes the sheet and starts the purchase', (
    tester,
  ) async {
    when(() => cubit.buyPlan(any(), any())).thenAnswer((_) async {});
    whenListen(cubit, Stream<BillingState>.empty(), initialState: ready);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => BlocProvider<BillingCubit>.value(
                  value: cubit,
                  child: const UpgradePlansSheet(
                    currentPlan: _starter,
                    annual: false,
                    canManage: true,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Upgrade to Growth'));
    await tester.pumpAndSettle();

    verify(() => cubit.buyPlan('growth', 'monthly')).called(1);
    expect(find.textContaining('Upgrade to Growth'), findsNothing);
  });

  testWidgets('a failed catalog offers a retry, not an empty sheet', (
    tester,
  ) async {
    await pump(
      tester,
      const BillingState(
        status: BillingStatus.ready,
        planCode: 'starter',
        effectiveStatus: 'active',
        playSupported: true,
        catalogFailed: true,
      ),
    );

    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('offline says so rather than offering an unbuyable plan', (
    tester,
  ) async {
    await pump(
      tester,
      const BillingState(
        status: BillingStatus.ready,
        planCode: 'starter',
        effectiveStatus: 'active',
        plans: _catalog,
        offline: true,
      ),
    );

    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.textContaining('Upgrade to Growth'), findsNothing);
  });

  testWidgets('an empty catalog shows placeholders, not a blank sheet', (
    tester,
  ) async {
    await pump(
      tester,
      const BillingState(
        status: BillingStatus.ready,
        planCode: 'starter',
        effectiveStatus: 'active',
        playSupported: true,
      ),
      settle: false,
    );

    expect(find.byType(PlanCardsSkeleton), findsOneWidget);
  });

  // Guards the race where a purchase lands while the sheet is still open.
  testWidgets('the top tier is told there is nothing above it', (tester) async {
    await pump(tester, ready, current: _business);

    expect(find.textContaining('top plan'), findsOneWidget);
    expect(find.text('Upgrade to Growth'), findsNothing);
  });
}
