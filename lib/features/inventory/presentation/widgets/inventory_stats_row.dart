import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/stat_card.dart';
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
      AppStatCard(
        title: 'Total Products',
        value: isLoading ? '—' : '${data.totalProducts}',
        icon: Icons.inventory_2_outlined,
        iconBg: AppColors.brandSoft,
        iconColor: AppColors.brand,
      ),
      AppStatCard(
        title: 'Low Stock Items',
        value: isLoading ? '—' : '${data.lowStockCount}',
        icon: Icons.warning_amber_rounded,
        iconBg: AppColors.errorSoft,
        iconColor: AppColors.error,
      ),
      AppStatCard(
        title: 'Warning Level',
        value: isLoading ? '—' : '${data.warningCount}',
        icon: Icons.error_outline,
        iconBg: AppColors.warningSoft,
        iconColor: AppColors.warning,
      ),
      AppStatCard(
        title: 'Not Tracked',
        value: isLoading ? '—' : '${data.notTrackedCount}',
        icon: Icons.remove_circle_outline_rounded,
        iconBg: AppColors.surfaceAlt,
        iconColor: AppColors.textMuted,
      ),
    ];

    return StatCardsRow(cards: cards);
  }
}
