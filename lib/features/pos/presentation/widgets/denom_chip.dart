import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
class DenomChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isExact;

  const DenomChip({
    super.key,
    required this.label,
    required this.onTap,
    this.isExact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isExact ? AppColors.brandSoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExact
                ? AppColors.brand.withValues(alpha: 0.3)
                : AppColors.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: getOutfitStyle(
            color: isExact ? AppColors.brand : AppColors.textSecondary,
            fontWeight: isExact ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
