import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';

class RecipeSummaryRow extends StatelessWidget {
  final List<RecipeLineFormEntry> lines;
  final TextEditingController sellingPriceController;
  final VoidCallback onEdit;

  const RecipeSummaryRow({
    super.key,
    required this.lines,
    required this.sellingPriceController,
    required this.onEdit,
  });

  static double _cost(List<RecipeLineFormEntry> lines) => lines.fold(
        0.0,
        (s, l) => s + (l.costPrice ?? 0.0) * l.quantity,
      );

  @override
  Widget build(BuildContext context) {
    final cost = _cost(lines);
    final hasCost = cost > 0;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: sellingPriceController,
      builder: (_, priceVal, _) {
        final price = double.tryParse(priceVal.text.trim());
        final margin = (price != null && price > 0 && hasCost)
            ? (price - cost) / price * 100
            : null;

        final Color accentColor;
        final Color bgColor;
        if (margin == null) {
          accentColor = AppColors.brand;
          bgColor = AppColors.brandSoft;
        } else if (margin >= 40) {
          accentColor = AppColors.success;
          bgColor = AppColors.successSoft;
        } else if (margin >= 20) {
          accentColor = AppColors.warning;
          bgColor = AppColors.warningSoft;
        } else {
          accentColor = AppColors.error;
          bgColor = AppColors.errorSoft;
        }

        return GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(Icons.blender_outlined, size: 16, color: accentColor),
                const SizedBox(width: 10),
                Expanded(
                  child: lines.isEmpty
                      ? Text(
                          'No ingredients yet — tap to add',
                          style: getOutfitStyle(
                              color: accentColor, fontSize: 13),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${lines.length} ingredient${lines.length == 1 ? '' : 's'}',
                              style: getOutfitStyle(
                                color: accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (hasCost)
                              Text(
                                margin != null
                                    ? '₱${cost.toStringAsFixed(2)} cost · ${margin.toStringAsFixed(0)}% margin'
                                    : '₱${cost.toStringAsFixed(2)} cost',
                                style: getOutfitStyle(
                                    color: accentColor, fontSize: 11),
                              ),
                          ],
                        ),
                ),
                Text(
                  'Edit recipe',
                  style: getOutfitStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: accentColor),
              ],
            ),
          ),
        );
      },
    );
  }
}
