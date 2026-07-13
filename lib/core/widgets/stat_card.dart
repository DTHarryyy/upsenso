import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';

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

  /// Short delta shown inside the trend pill — e.g. "+100%". Keep it brief;
  /// the comparison window goes in [changePeriod] so neither truncates.
  final String? changeLabel;

  /// Muted comparison window beside the pill — e.g. "vs last week". Optional;
  /// omit it and only the pill shows.
  final String? changePeriod;

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
    this.changePeriod,
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
        color: isSelected
            ? iconColor.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
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
        // mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.money(
                        context,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          if (changeLabel != null) ...[
            const SizedBox(height: 6),
            _TrendRow(
              label: changeLabel!,
              period: changePeriod,
              positive: positive,
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

/// Trend line for [AppStatCard]: a trending-up/down glyph followed by the
/// delta and its comparison window, all tinted green/red on one line.
class _TrendRow extends StatelessWidget {
  final String label;
  final String? period;
  final bool positive;

  const _TrendRow({required this.label, this.period, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.success : AppColors.error;
    // final size = (11 * ResponsiveTypography.scale(context)).roundToDouble();
    final text = period == null ? label : '$label $period';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: AppTextStyles.caption(context).copyWith(
              color: color,
              // fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
  // final double gap;

  const StatCardsRow({super.key, required this.cards, this.minTileWidth = 165});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final gap = Breakpoints.isPhone(context) ? 8.0 : 12.0;
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
                    Expanded(
                      child: j < slice.length ? slice[j] : const SizedBox(),
                    ),
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
