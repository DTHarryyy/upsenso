import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/domain/entities/product_variant.dart';
import 'package:pos/features/products/widgets/product_selection_sheet.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final List<ProductVariant> variants;
  final void Function(ProductVariant variant, double quantity)? onAddToCart;
  final VoidCallback? onEdit;

  /// variantId → branch-filtered stock quantity.
  /// Built by ProductsPage from inventory_levels for the selected branch.
  /// Empty map = no inventory data loaded yet (no badge shown).
  final Map<String, int> variantStock;

  const ProductCard({
    super.key,
    required this.product,
    required this.variants,
    this.onAddToCart,
    this.onEdit,
    this.variantStock = const {},
  });

  double? _minPrice() {
    final active = variants.where((v) => v.isActive).toList();
    if (active.isEmpty) return null;
    return active.map((v) => v.price).reduce(min);
  }

  Widget _imagePlaceholder(bool isFraction) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.brandSoft,
      child: Center(
        child: Icon(
          isFraction ? Icons.scale_outlined : Icons.inventory_2_outlined,
          size: 32,
          color: AppColors.brand.withAlpha(180),
        ),
      ),
    );
  }

  String _priceLabel() {
    final price = _minPrice();
    if (price == null) return '—';
    if (product.hasVariants) return '₱${price.toStringAsFixed(2)}';
    return '₱${price.toStringAsFixed(2)}';
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
                  variantStock: variantStock,
                  onConfirm: onAddToCart,
                  onEdit: onEdit,
                ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: product.imagePath != null
                            ? Image.file(
                                File(product.imagePath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    _imagePlaceholder(isFraction),
                              )
                            : _imagePlaceholder(isFraction),
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

                      Positioned(
                        top: 5,
                        right: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (product.hasVariants)
                              Container(
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
                            Builder(
                              builder: (_) {
                                final tracked = variants
                                    .where((v) => v.trackStock && v.isActive)
                                    .toList();
                                if (tracked.isEmpty || variantStock.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final total = tracked.fold(
                                  0,
                                  (s, v) => s + (variantStock[v.id] ?? 0),
                                );
                                final inStock = total > 0;
                                const green = Color(0xFF2E7D32);
                                const red = Color(0xFFC62828);
                                return Padding(
                                  padding: EdgeInsets.only(
                                    top: product.hasVariants ? 4 : 0,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (inStock ? green : red).withAlpha(
                                        180,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      inStock ? '$total' : '0',
                                      style: getOutfitStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
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
