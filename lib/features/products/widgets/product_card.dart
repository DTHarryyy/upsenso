import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/database/app_database.dart';

class ProductCard extends StatelessWidget {
  final ProductsTableData product;
  final List<ProductVariantsTableData> variants;

  const ProductCard({
    super.key,
    required this.product,
    required this.variants,
  });

  double? _minPrice() {
    final active = variants.where((v) => v.isActive).toList();
    if (active.isEmpty) return null;
    return active.map((v) => v.price).reduce(min);
  }

  int _totalStock() => variants.fold(0, (acc, v) => acc + v.stock);

  Color _stockColor() {
    final total = _totalStock();
    if (total == 0) return AppColors.outOfStock;
    if (total <= 5) return AppColors.lowStock;
    return AppColors.inStock;
  }

  String _priceLabel() {
    final price = _minPrice();
    if (price == null) return '—';
    if (product.hasVariants) return 'From \$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.borderSoft, width: 1),
      ),
      elevation: 1.5,
      shadowColor: AppColors.brandSoft.withAlpha(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(10),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 32,
                          color: AppColors.brand.withAlpha(180),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _stockColor(),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                textAlign: TextAlign.left,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _priceLabel(),
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (product.hasVariants) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.brand.withAlpha(60)),
                  ),
                  child: Text(
                    '${variants.length} variants',
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
