import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

/// Generic white card shell used across reports, dashboard, expenses, inventory.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: child,
    );
  }
}

/// The one KPI/stat tile used across every page in the app: an accent icon
/// badge, a hero value, a muted label, and an optional trend line. Pass
/// [onTap] (and optionally [isSelected]) to reuse this as a tappable filter
/// chip — e.g. the alerts and notifications summary rows.
class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? changeLabel;
  final bool? isPositive;
  final IconData icon;

  /// Icon badge background. Defaults to a soft tint of [iconColor].
  final Color? iconBg;
  final Color iconColor;

  final VoidCallback? onTap;
  final bool isSelected;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    this.changeLabel,
    this.isPositive,
    required this.icon,
    this.iconBg,
    required this.iconColor,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = iconBg ?? iconColor.withValues(alpha: 0.12);
    final positive = isPositive ?? true;

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? iconColor.withValues(alpha: 0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? iconColor : AppColors.borderSoft,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.headline(
                context,
              ).copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (changeLabel != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  positive ? IconlyBold.arrow_up_2 : IconlyBold.arrow_down_2,
                  size: 14,
                  color: positive ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    changeLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: positive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

/// How many columns a KPI/stat grid should use for the given available
/// width — never more than [cardCount], never fewer than 2 once there are
/// at least 2 cards, and never so few that cards overflow into a scroll.
/// Shared by [StatCardsRow] and the matching loading skeletons so the
/// shimmer always lines up with the real layout.
int kpiColumnCount(
  double maxWidth,
  int cardCount, {
  double minTileWidth = 165,
  double gap = 12,
}) {
  if (cardCount <= 1) return 1;
  final fit = ((maxWidth + gap) / (minTileWidth + gap)).floor();
  final minCols = math.min(2, cardCount);
  return fit.clamp(minCols, cardCount);
}

/// Responsive grid of KPI/stat cards. Fits as many columns as the available
/// width allows (desktop: one row; tablet/phone: 2–3 columns) — it never
/// scrolls and never leaves a lone card stretched full-width.
class StatCardsRow extends StatelessWidget {
  final List<Widget> cards;
  final double minTileWidth;
  final double gap;

  const StatCardsRow({
    super.key,
    required this.cards,
    this.minTileWidth = 165,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (_, constraints) {
        final columns = kpiColumnCount(
          constraints.maxWidth,
          cards.length,
          minTileWidth: minTileWidth,
          gap: gap,
        );

        final rows = <Widget>[];
        for (var i = 0; i < cards.length; i += columns) {
          if (i > 0) rows.add(SizedBox(height: gap));
          final end = math.min(i + columns, cards.length);
          final slice = cards.sublist(i, end);
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: gap),
                    Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}
