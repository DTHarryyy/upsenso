import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';

class InventoryStatsRow extends StatelessWidget {
  final InventoryData data;
  final bool isLoading;

  const InventoryStatsRow({
    super.key,
    required this.data,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        label: 'Total Products',
        value: isLoading ? '—' : '${data.totalProducts}',
        icon: Icons.inventory_2_outlined,
        iconBg: AppColors.brandSoft,
        iconColor: AppColors.brand,
        borderColor: AppColors.brand.withValues(alpha: 0.2),
      ),
      _StatCard(
        label: 'Low Stock Items',
        value: isLoading ? '—' : '${data.lowStockCount}',
        icon: Icons.warning_amber_rounded,
        iconBg: AppColors.errorSoft,
        iconColor: AppColors.error,
        borderColor: AppColors.error.withValues(alpha: 0.2),
      ),
      _StatCard(
        label: 'Warning Level',
        value: isLoading ? '—' : '${data.warningCount}',
        icon: Icons.error_outline,
        iconBg: AppColors.warningSoft,
        iconColor: AppColors.warning,
        borderColor: AppColors.warning.withValues(alpha: 0.2),
      ),
      _StatCard(
        label: 'Not Tracked',
        value: isLoading ? '—' : '${data.notTrackedCount}',
        icon: Icons.remove_circle_outline_rounded,
        iconBg: AppColors.surfaceAlt,
        iconColor: AppColors.textMuted,
        borderColor: AppColors.borderSoft,
      ),
    ];

    // Wrap naturally: each card has a minimum width of 180.
    // On wide screens all three sit side-by-side; on narrow screens they
    // wrap to a 2-wide or 1-wide grid automatically — no breakpoint logic needed.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardMinWidth = 180.0;
        final cardsPerRow = (constraints.maxWidth / cardMinWidth).floor().clamp(1, 3);
        final spacing = 12.0;
        final totalSpacing = spacing * (cardsPerRow - 1);
        final cardWidth = (constraints.maxWidth - totalSpacing) / cardsPerRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((c) => SizedBox(width: cardWidth, child: c))
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color borderColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: getOutfitStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: getOutfitStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
