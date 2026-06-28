import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';

/// Icon button that opens a filter sheet; shows an amber dot when any filter
/// in that sheet is active. Pair with [showModalBottomSheet] or `showAppModal`.
class AppFilterButton extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onTap;

  const AppFilterButton({
    super.key,
    required this.hasActiveFilters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasActiveFilters ? AppColors.brand : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasActiveFilters ? AppColors.brand : AppColors.borderSoft,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              IconlyLight.filter,
              size: 20,
              color: hasActiveFilters ? Colors.white : AppColors.textSecondary,
            ),
            if (hasActiveFilters)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBBF24),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
