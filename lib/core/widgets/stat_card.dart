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

/// Stat card: icon badge + value + title + optional change label.
/// Used consistently across Dashboard, Reports, Inventory, and Expenses.
class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? changeLabel;
  final bool? isPositive;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    this.changeLabel,
    this.isPositive,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (changeLabel != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  (isPositive ?? true)
                      ? IconlyBold.arrow_up_2
                      : IconlyBold.arrow_down_2,
                  size: 15,
                  color: (isPositive ?? true)
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    changeLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: (isPositive ?? true)
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Responsive row of stat cards: single row on wide screens, 2-column grid on narrow.
class StatCardsRow extends StatelessWidget {
  final List<Widget> cards;
  const StatCardsRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        if (c.maxWidth > 800) {
          return Row(
            children:
                cards
                    .map((w) => Expanded(child: w))
                    .expand((w) => [w, const SizedBox(width: 12)])
                    .toList()
                  ..removeLast(),
          );
        }
        // 2-column grid for narrow screens
        final rows = <Widget>[];
        for (var i = 0; i < cards.length; i += 2) {
          if (i > 0) rows.add(const SizedBox(height: 8));
          final pair = cards.sublist(i, (i + 2).clamp(0, cards.length));
          rows.add(
            Row(
              children:
                  pair
                      .map((w) => Expanded(child: w))
                      .expand((w) => [w, const SizedBox(width: 8)])
                      .toList()
                    ..removeLast(),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}
