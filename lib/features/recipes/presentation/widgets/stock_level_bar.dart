import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

/// A thin color-coded progress bar showing current stock relative to its
/// minimum threshold. Green = healthy, amber = at/below minimum, red = empty.
///
/// When [minStock] is null the bar only communicates empty (red) vs
/// non-empty (green, full), since there is no threshold to scale against.
class StockLevelBar extends StatelessWidget {
  final double stock;
  final int? minStock;
  final double height;

  const StockLevelBar({
    super.key,
    required this.stock,
    required this.minStock,
    this.height = 6,
  });

  ({Color color, double fill}) _resolve() {
    if (stock <= 0) return (color: AppColors.outOfStock, fill: 0.04);

    final min = minStock;
    if (min == null || min <= 0) {
      // No threshold — just show a healthy full bar.
      return (color: AppColors.inStock, fill: 1);
    }

    // Minimum sits at the 50% mark; 2× minimum reads as "full".
    final fill = (stock / (min * 2)).clamp(0.05, 1).toDouble();
    final color = stock <= min ? AppColors.lowStock : AppColors.inStock;
    return (color: color, fill: fill);
  }

  @override
  Widget build(BuildContext context) {
    final r = _resolve();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: AppColors.surfaceAlt),
          FractionallySizedBox(
            widthFactor: r.fill,
            child: Container(height: height, color: r.color),
          ),
        ],
      ),
    );
  }
}
