import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/features/products/widgets/product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<(ProductsTableData, List<ProductVariantsTableData>)> items;
  final VoidCallback? onAddProduct;

  const ProductGrid({super.key, required this.items, this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return ProductAdd(onTap: onAddProduct);
        final (product, variants) = items[index - 1];
        return ProductCard(product: product, variants: variants);
      },
      padding: EdgeInsets.zero,
    );
  }
}

class ProductAdd extends StatelessWidget {
  final VoidCallback? onTap;

  const ProductAdd({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.brandSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.brand.withAlpha(80),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        splashColor: AppColors.brand.withAlpha(30),
        highlightColor: AppColors.brand.withAlpha(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brand.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add Product',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
