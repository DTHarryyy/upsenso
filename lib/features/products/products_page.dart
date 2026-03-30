import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/features/products/widgets/product_category_chips.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/products/checkout/product_cart_page.dart';
import 'package:pos/features/products/widgets/product_grid.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _categoriesDao = sl<CategoriesDao>();
  final _productsDao = sl<ProductsDao>();
  final _productVariantsDao = sl<ProductVariantsDao>();
  final _cartService = sl<CartService>();

  String? selectedCategoryId;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final businessId = authState is AuthAuthenticated
        ? authState.user.businessId
        : null;

    return ListenableBuilder(
      listenable: _cartService,
      builder: (context, _) {
        final cartNotEmpty = _cartService.isNotEmpty;
        final cartTotal = _cartService.items
            .fold(0.0, (s, i) => s + i.total + i.taxAmount);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              SafeArea(
                child: StreamBuilder<List<ProductVariantsTableData>>(
                  stream: businessId != null
                      ? _productVariantsDao.watchByBusinessId(businessId)
                      : const Stream.empty(),
                  builder: (context, variantsSnap) {
                    final allVariants = variantsSnap.data ?? [];
                    final variantsMap =
                        <String, List<ProductVariantsTableData>>{};
                    for (final v in allVariants) {
                      variantsMap.putIfAbsent(v.productId, () => []).add(v);
                    }

                    return StreamBuilder<List<CategoriesTableData>>(
                      stream: businessId != null
                          ? _categoriesDao.watchByBusinessId(businessId)
                          : const Stream.empty(),
                      builder: (context, catsSnap) {
                        final dbCategories = catsSnap.data ?? [];

                        if (selectedCategoryId != null &&
                            !dbCategories
                                .any((c) => c.id == selectedCategoryId)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => selectedCategoryId = null);
                            }
                          });
                        }

                        return StreamBuilder<List<ProductsTableData>>(
                          stream: businessId != null
                              ? _productsDao.watchByBusinessId(businessId)
                              : const Stream.empty(),
                          builder: (context, productsSnap) {
                            if (productsSnap.connectionState ==
                                    ConnectionState.waiting &&
                                !productsSnap.hasData) {
                              return _buildLoadingState();
                            }

                            final allProducts = productsSnap.data ?? [];

                            final filtered = allProducts
                                .where((p) =>
                                    selectedCategoryId == null ||
                                    p.categoryId == selectedCategoryId)
                                .where((p) =>
                                    searchQuery.isEmpty ||
                                    p.name
                                        .toLowerCase()
                                        .contains(searchQuery.toLowerCase()))
                                .toList();

                            final items = filtered
                                .map((p) => (
                                      p,
                                      variantsMap[p.id] ??
                                          <ProductVariantsTableData>[]
                                    ))
                                .toList();

                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                  16, 12, 16, cartNotEmpty ? 80 : 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppSearchBar(
                                    hint: 'Search products...',
                                    onChanged: (v) =>
                                        setState(() => searchQuery = v),
                                  ),
                                  const SizedBox(height: 12),
                                  ProductCategoryChips(
                                    categories: dbCategories,
                                    selectedCategoryId: selectedCategoryId,
                                    onCategorySelected: (id) =>
                                        setState(() => selectedCategoryId = id),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: allProducts.isEmpty
                                        ? _buildEmptyState(context)
                                        : filtered.isEmpty
                                            ? _buildNoResultsState(context)
                                            : ProductGrid(
                                                items: items,
                                                onAddProduct: () => context
                                                    .push(AppRoutes.addProduct),
                                                onAddToCart:
                                                    (product, variant, qty) {
                                                  _cartService.addOrIncrement(
                                                    variantId: variant.id,
                                                    name: product.name,
                                                    variant: variant.name ==
                                                            'Default'
                                                        ? ''
                                                        : variant.name,
                                                    unitPrice: variant.price,
                                                    taxRate: product.tax,
                                                    qty: qty,
                                                  );
                                                  final qtyLabel =
                                                      product.sellBy ==
                                                              'fraction'
                                                          ? qty.toStringAsFixed(
                                                              1)
                                                          : qty
                                                              .toInt()
                                                              .toString();
                                                  final label =
                                                      variant.name == 'Default'
                                                          ? product.name
                                                          : '${product.name} · ${variant.name}';
                                                  if (mounted) {
                                                    StatusSnack.show(
                                                      context,
                                                      type: StatusType.success,
                                                      message:
                                                          '$label × $qtyLabel added to cart',
                                                    );
                                                  }
                                                },
                                                onEditProduct: (product) =>
                                                    context.push(
                                                  AppRoutes.editProduct,
                                                  extra: product,
                                                ),
                                              ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Animated cart bar
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  offset: cartNotEmpty ? Offset.zero : const Offset(0, 1.5),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: cartNotEmpty ? 1.0 : 0.0,
                    child: SafeArea(
                      top: false,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProductCartPage(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_cartService.itemCount}',
                                  style: getOutfitStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'View Cart',
                                  style: getOutfitStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                ProductCartPage.fmtPrice(cartTotal),
                                style: getOutfitStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.brand,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: AppTextStyles.subtitle(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Product" to get started',
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.addProduct),
            icon: const Icon(Icons.add_rounded, color: AppColors.brand),
            label: Text(
              'Add Product',
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No products match your search',
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              searchQuery = '';
              selectedCategoryId = null;
            }),
            child: Text(
              'Clear filters',
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
