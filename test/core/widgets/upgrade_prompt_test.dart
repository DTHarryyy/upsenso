import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/widgets/crown_icon.dart';

import 'package:pos/core/widgets/upgrade_prompt.dart';

/// The sheet's job is to answer "which plan fixes this?" — it used to open
/// titled "This is a paid feature" (restating the obstacle) with a CTA that
/// offered a browse rather than the action.
void main() {
  /// A GoRouter is required: showUpgradePrompt captures one up front so the CTA
  /// survives callers that pop themselves before opening it.
  Future<void> pumpAndOpen(
    WidgetTester tester,
    UpgradeMoment moment, {
    String? requiredPlan,
    String? detail,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Builder(
              builder: (inner) => ElevatedButton(
                onPressed: () => showUpgradePrompt(
                  inner,
                  moment,
                  requiredPlan: requiredPlan,
                  detail: detail,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('locked module', () {
    testWidgets('names the tier in the title and commits in the CTA', (
      tester,
    ) async {
      await pumpAndOpen(
        tester,
        UpgradeMoment.lockedModule,
        requiredPlan: 'growth',
      );

      expect(find.text('Included in Growth'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
      // The old copy offered a browse, not the action.
      expect(find.text('See what\'s included'), findsNothing);
      expect(find.text('This is a paid feature'), findsNothing);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('starter locks say Starter', (tester) async {
      await pumpAndOpen(
        tester,
        UpgradeMoment.lockedModule,
        requiredPlan: 'starter',
      );

      expect(find.text('Included in Starter'), findsOneWidget);
    });

    testWidgets('falls back gracefully when the tier is unknown', (
      tester,
    ) async {
      await pumpAndOpen(tester, UpgradeMoment.lockedModule);

      expect(find.text('This is a paid feature'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
    });

    // The redundancy guard. The first draft had three crowns (nav badge, hero,
    // tier pill) and named the tier twice in one sheet; a premium signal
    // repeated is a premium signal spent.
    testWidgets('shows exactly one crown', (tester) async {
      await pumpAndOpen(
        tester,
        UpgradeMoment.lockedModule,
        requiredPlan: 'growth',
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is CrownIcon,
        ),
        findsOneWidget,
      );
      // And the tier appears once, in the title — no pill echoing it.
      expect(find.textContaining('Growth'), findsOneWidget);
    });

    testWidgets('a caller-supplied detail becomes the body', (tester) async {
      await pumpAndOpen(
        tester,
        UpgradeMoment.lockedModule,
        requiredPlan: 'growth',
        detail: 'Export your reports as PDF or Excel.',
      );

      expect(find.text('Export your reports as PDF or Excel.'), findsOneWidget);
    });
  });

  group('other moments keep their own copy', () {
    testWidgets('branchCap', (tester) async {
      await pumpAndOpen(tester, UpgradeMoment.branchCap);

      expect(find.text('Running a second location?'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
    });

    testWidgets('seatCap', (tester) async {
      await pumpAndOpen(tester, UpgradeMoment.seatCap);

      expect(find.text('Give your staff their own login'), findsOneWidget);
      expect(find.text('See plans'), findsOneWidget);
    });

    // Every moment inherits the hero, so none may render a bare sheet.
    testWidgets('all moments render the crown hero', (tester) async {
      for (final moment in UpgradeMoment.values) {
        await pumpAndOpen(tester, moment);
        expect(
          find.byWidgetPredicate(
            (w) => w is CrownIcon,
          ),
          findsOneWidget,
          reason: '$moment renders a crown',
        );
      }
    });
  });

  testWidgets('Not now dismisses without navigating', (tester) async {
    await pumpAndOpen(
      tester,
      UpgradeMoment.lockedModule,
      requiredPlan: 'growth',
    );

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Included in Growth'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
