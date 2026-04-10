import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';

class StockStatusBadge extends StatelessWidget {
  final StockStatus status;

  const StockStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      StockStatus.inStock => ('In Stock', AppColors.successSoft, AppColors.success),
      StockStatus.warning => ('Warning', AppColors.warningSoft, AppColors.warning),
      StockStatus.lowStock => ('Low Stock', AppColors.errorSoft, AppColors.error),
      StockStatus.notTracked => ('Not Tracked', AppColors.surfaceAlt, AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: getOutfitStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
