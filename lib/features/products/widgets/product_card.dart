import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/features/products/widgets/product_selection_sheet.dart';

class ProductCard extends StatelessWidget {
  final ProductsTableData product;
  final List<ProductVariantsTableData> variants;
  final void Function(ProductVariantsTableData variant, double quantity)?
      onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.variants,
    this.onAddToCart,
  });

  double? _minPrice() {
    final active = variants.where((v) => v.isActive).toList();
    if (active.isEmpty) return null;
    return active.map((v) => v.price).reduce(min);
  }



  String _priceLabel() {
    final price = _minPrice();
    if (price == null) return '—';
    if (product.hasVariants) return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isFraction = product.sellBy == 'fraction';

    return Opacity(
      opacity: product.isActive ? 1.0 : .5,
      child: Card(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.borderSoft, width: 1),
        ),
        elevation: 1.5,
        shadowColor: AppColors.brandSoft.withAlpha(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: AppColors.brand.withAlpha(25),
          highlightColor: AppColors.brand.withAlpha(15),
          hoverColor: AppColors.brandSoft.withAlpha(120),
          onTap: !product.isActive
              ? null
              : () => showProductSelectionSheet(
                    context,
                    product: product,
                    variants: variants,
                    onConfirm: onAddToCart,
                  ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            isFraction
                                ? Icons.scale_outlined
                                : Icons.inventory_2_outlined,
                            size: 32,
                            color: AppColors.brand.withAlpha(180),
                          ),
                        ),
                      ),

                      if (!product.isActive)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.textMuted.withAlpha(60),
                              ),
                            ),
                            child: Text(
                              'Inactive',
                              style: getOutfitStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),

                      if (product.hasVariants)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.brand.withAlpha(60),
                              ),
                            ),
                            child: Text(
                              '${variants.length} vars',
                              style: getOutfitStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  product.name,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

               Text(
                  _priceLabel(),
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
