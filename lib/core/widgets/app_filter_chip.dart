import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;
  final Color? selectedColor;
  final Color? badgeColor;
  final Color? badgeTextColor;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
    this.selectedColor,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedColor ?? AppColors.brand;
    final activeBg = isSelected
        ? activeColor
        : AppColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: activeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderSoft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(IconlyLight.tick_square, size: 14, color: AppColors.textInverse),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.18)
                      : (badgeColor ?? AppColors.warningSoft),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$badgeCount',
                  style: getOutfitStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? activeColor
                        : (badgeTextColor ?? AppColors.warning),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
