import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
class ProductCategoryChips extends StatelessWidget {
  final List<CategoriesTableData> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const ProductCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedCategoryId == null;
            return ChoiceChip(
              label: Text(
                'All',
                style: getOutfitStyle(
                  color:
                      isSelected ? AppColors.surface : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.brand,
              checkmarkColor: AppColors.surface,
              side: BorderSide(
                color: isSelected ? AppColors.brand : AppColors.borderSoft,
                width: isSelected ? 2 : 1,
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(null),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }
          final cat = categories[index - 1];
          final isSelected = cat.id == selectedCategoryId;
          return ChoiceChip(
            label: Text(
              cat.name,
              style: getOutfitStyle(
                color: isSelected ? AppColors.surface : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.brand,
            checkmarkColor: AppColors.surface,
            side: BorderSide(
              color: isSelected ? AppColors.brand : AppColors.borderSoft,
              width: isSelected ? 2 : 1,
            ),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(cat.id),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }
}
