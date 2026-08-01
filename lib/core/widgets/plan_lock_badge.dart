import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/core/widgets/crown_icon.dart';

/// A small gold crown marking a nav entry the current plan doesn't include
/// (design §4.7: never a hidden control — show it, and let the tap explain).
///
/// Icon only, no text. Three locked rows in a drawer used to mean three text
/// pills shouting "Growth" over the labels they were meant to annotate; the
/// crown carries the same meaning quietly, and the tooltip has the detail for
/// anyone who wants it. That tooltip is the whole affordance, so it covers hover
/// on desktop *and* long-press on mobile.
///
/// Distinct from [PlanBadge], which shows the tier you *have*.
class PlanLockBadge extends StatelessWidget {
  /// Plan code from [requiredPlanFor] — 'starter', 'growth', …
  final String planCode;

  final double size;

  /// Set false where an ancestor already tooltips the whole control and names
  /// the tier — the collapsed sidebar rail does. Two nested tooltips fight over
  /// the same pointer and only one ever wins.
  final bool showTooltip;

  const PlanLockBadge({
    super.key,
    required this.planCode,
    this.size = 20,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final crown = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.premiumSoft,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      alignment: Alignment.center,
      child: CrownIcon(size: size * 0.58, color: AppColors.premium),
    );

    if (!showTooltip) return crown;
    return Tooltip(
      message: '${planLabelOf(planCode)} plan',
      waitDuration: const Duration(milliseconds: 300),
      child: crown,
    );
  }
}
