import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/widgets/report_section.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

/// One row of a revenue-ranked breakdown (product or category).
class RankedRevenueItem {
  final String name;
  final String? subtitle; // e.g. "12 sold" for products; null for categories
  final double value; // revenue
  final double share; // 0..1 of the period total

  const RankedRevenueItem({
    required this.name,
    required this.value,
    required this.share,
    this.subtitle,
  });
}

/// A compact "top N" ranked card used by both the Sales-by-Product and
/// Sales-by-Category sections. [items] is already truncated to what should
/// show inline; "View all" only appears when [totalCount] exceeds that.
class ReportRankedListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<RankedRevenueItem> items;
  final int totalCount;
  final VoidCallback? onViewAll;

  static const _palette = AppColors.chartPalette;

  const ReportRankedListCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.totalCount,
    this.iconColor,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasMore = onViewAll != null && totalCount > items.length;

    return ReportSection(
      title: title,
      icon: icon,
      iconColor: iconColor,
      subtitle: 'Top ${items.length} of $totalCount by revenue',
      trailing: hasMore ? ReportViewAllButton(onTap: onViewAll!) : null,
      child: items.isEmpty
          ? const _RankedEmpty()
          : Column(
              children: List.generate(
                items.length,
                (i) => _RankedRow(
                  rank: i + 1,
                  color: _palette[i % _palette.length],
                  item: items[i],
                  isLast: i == items.length - 1,
                ),
              ),
            ),
    );
  }
}

/// Shared "View all" header action used by report breakdown cards.
class ReportViewAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const ReportViewAllButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: AppTextStyles.caption(
          context,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
      child: const Text('View all'),
    );
  }
}

class _RankedRow extends StatelessWidget {
  final int rank;
  final Color color;
  final RankedRevenueItem item;
  final bool isLast;

  const _RankedRow({
    required this.rank,
    required this.color,
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (item.share * 100);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$rank',
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _ShareBar(share: item.share, color: color),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtCurrency(item.value),
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle ?? '${pct.toStringAsFixed(1)}%',
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Thin proportional bar — quick visual weight of each row's share.
class _ShareBar extends StatelessWidget {
  final double share;
  final Color color;
  const _ShareBar({required this.share, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: share.clamp(0.0, 1.0),
        minHeight: 4,
        backgroundColor: color.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _RankedEmpty extends StatelessWidget {
  const _RankedEmpty();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'No sales data',
          style: AppTextStyles.body(
            context,
          ).copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
