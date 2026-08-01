import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/crown_icon.dart';
import 'package:pos/core/widgets/plan_lock_badge.dart';

/// The badge is icon-only by design: three locked rows in a drawer used to mean
/// three text pills shouting the tier over the labels they annotate. The
/// tooltip is the entire affordance carrying the detail, so losing it silently
/// would leave a crown nobody can decode.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );
  }

  testWidgets('renders a gold crown and no plan text', (tester) async {
    await pump(tester, const PlanLockBadge(planCode: 'growth'));

    final crown = tester.widget<CrownIcon>(find.byType(CrownIcon));
    expect(crown.color, AppColors.premium);
    // The tier is never spelled out on the badge itself.
    expect(find.text('Growth'), findsNothing);
    expect(find.textContaining('plan'), findsNothing);
  });

  testWidgets('the tooltip names the tier', (tester) async {
    await pump(tester, const PlanLockBadge(planCode: 'growth'));

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Growth plan');
  });

  testWidgets('a starter lock names Starter, not a hardcoded tier', (
    tester,
  ) async {
    await pump(tester, const PlanLockBadge(planCode: 'starter'));

    expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Starter plan');
  });

  // The collapsed sidebar rail already wraps the whole tile in a tooltip that
  // names the tier; a second nested one fights it for the same pointer.
  testWidgets('showTooltip: false drops the tooltip but keeps the crown', (
    tester,
  ) async {
    await pump(
      tester,
      const PlanLockBadge(planCode: 'growth', showTooltip: false),
    );

    expect(find.byType(Tooltip), findsNothing);
    expect(find.byType(CrownIcon), findsOneWidget);
  });

  testWidgets('size scales the crown with the container', (tester) async {
    await pump(tester, const PlanLockBadge(planCode: 'growth', size: 14));

    expect(tester.widget<CrownIcon>(find.byType(CrownIcon)).size, 14 * 0.58);
  });
}
