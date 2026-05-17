import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
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
        icon: IconlyLight.category,
        iconBg: AppColors.brandSoft,
        iconColor: AppColors.brand,
      ),
      AppStatCard(
        title: 'Low Stock Items',
        value: isLoading ? '—' : '${data.lowStockCount}',
        icon: IconlyBold.danger,
        iconBg: AppColors.errorSoft,
        iconColor: AppColors.error,
      ),
      AppStatCard(
        title: 'Warning Level',
        value: isLoading ? '—' : '${data.warningCount}',
        icon: IconlyLight.danger,
        iconBg: AppColors.warningSoft,
        iconColor: AppColors.warning,
      ),
      AppStatCard(
        title: 'Not Tracked',
        value: isLoading ? '—' : '${data.notTrackedCount}',
        icon: IconlyLight.delete,
        iconBg: AppColors.surfaceAlt,
        iconColor: AppColors.textMuted,
      ),
    ];

    return StatCardsRow(cards: cards);
  }
}
