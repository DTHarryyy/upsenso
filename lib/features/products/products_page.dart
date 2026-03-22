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
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/core/routes/app_routes.dart';
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

  String? selectedCategoryId;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final businessId = authState is AuthAuthenticated
        ? authState.user.businessId
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      
      body: SafeArea(
        child: StreamBuilder<List<ProductVariantsTableData>>(
          stream: businessId != null
              ? _productVariantsDao.watchByBusinessId(businessId)
              : const Stream.empty(),
          builder: (context, variantsSnap) {
            final allVariants = variantsSnap.data ?? [];
            final variantsMap = <String, List<ProductVariantsTableData>>{};
            for (final v in allVariants) {
              variantsMap.putIfAbsent(v.productId, () => []).add(v);
            }

            return StreamBuilder<List<CategoriesTableData>>(
              stream: businessId != null
                  ? _categoriesDao.watchByBusinessId(businessId)
                  : const Stream.empty(),
              builder: (context, catsSnap) {
                final dbCategories = catsSnap.data ?? [];

                // Reset selection if selected category was deleted
                if (selectedCategoryId != null &&
                    !dbCategories.any((c) => c.id == selectedCategoryId)) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => setState(() => selectedCategoryId = null),
                  );
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductSearchBar(
                            onSearchChanged: (v) =>
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

class ProductSearchBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const ProductSearchBar({super.key, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search products',
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 0,
          horizontal: 12,
        ),
      ),
      style: getOutfitStyle(color: AppColors.textPrimary),
      onChanged: onSearchChanged,
    );
  }
}

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
                borderRadius: BorderRadius.circular(10),
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
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }
}
