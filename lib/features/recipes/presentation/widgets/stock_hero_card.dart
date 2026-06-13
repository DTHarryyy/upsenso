import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/recipes/domain/entities/ingredient.dart';
import 'package:pos/features/recipes/presentation/widgets/stock_level_bar.dart';
import 'package:pos/features/recipes/utils/quantity_format.dart';

/// The top card on the ingredient detail page: current stock, a status pill,
/// and a gauge relative to the low-stock threshold.
class StockHeroCard extends StatelessWidget {
  final Ingredient ingredient;
  const StockHeroCard({super.key, required this.ingredient});

  ({Color color, String label}) _status() {
    if (ingredient.stock <= 0) {
      return (color: AppColors.outOfStock, label: 'Out of stock');
    }
    if (ingredient.lowStockAlert != null &&
        ingredient.stock <= ingredient.lowStockAlert!) {
      return (color: AppColors.lowStock, label: 'Low stock');
    }
    return (color: AppColors.inStock, label: 'In stock');
  }

  @override
  Widget build(BuildContext context) {
    final unit = ingredient.unit ?? 'pcs';
    final s = _status();
    final min = ingredient.lowStockAlert;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Stock',
                style: getOutfitStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _StatusPill(color: s.color, label: s.label),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatQuantity(ingredient.stock),
                style: getOutfitStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: getOutfitStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StockLevelBar(stock: ingredient.stock, minStock: min, height: 6),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: getOutfitStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              if (min != null)
                Text(
                  'Min $min $unit',
                  style: getOutfitStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Text(
                  'No minimum set',
                  style: getOutfitStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
