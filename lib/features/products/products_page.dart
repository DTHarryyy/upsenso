import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/products/checkout/product_cart_page.dart';
import 'package:pos/features/products/widgets/product_category_chips.dart';
import 'package:pos/features/products/widgets/product_grid.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  // ── Services / DAOs ───────────────────────────────────────────────────────
  final _cartService = sl<CartService>();
  final _categoriesDao = sl<CategoriesDao>();
  final _productsDao = sl<ProductsDao>();
  final _variantsDao = sl<ProductVariantsDao>();
  final _levelsDao = sl<InventoryLevelsDao>();

  // ── Filter state ──────────────────────────────────────────────────────────
  String? _selectedCategoryId;
  String _searchQuery = '';

  // ── Stream data ───────────────────────────────────────────────────────────
  List<InventoryLevelsTableData> _levels = [];
  List<ProductVariantsTableData> _allVariants = [];
  List<CategoriesTableData> _categories = [];
  List<ProductsTableData> _products = [];
  bool _productsLoaded = false;

  final List<StreamSubscription<dynamic>> _subs = [];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Defer one frame so BuildContext is fully ready to read BLoC state.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initStreams());
  }

  void _initStreams() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    final businessId =
        authState is AuthAuthenticated ? authState.user.businessId : null;

    if (businessId == null) {
      setState(() => _productsLoaded = true);
      return;
    }

    _subs.addAll([
      _levelsDao.watchByBusinessId(businessId).listen(
        (data) { if (mounted) setState(() => _levels = data); },
      ),
      _variantsDao.watchByBusinessId(businessId).listen(
        (data) { if (mounted) setState(() => _allVariants = data); },
      ),
      _categoriesDao.watchByBusinessId(businessId).listen((data) {
        if (!mounted) return;
        setState(() {
          _categories = data;
          // Auto-clear a category selection that was deleted.
          if (_selectedCategoryId != null &&
              !data.any((c) => c.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
        });
      }),
      _productsDao.watchByBusinessId(businessId).listen((data) {
        if (!mounted) return;
        setState(() {
          _products = data;
          _productsLoaded = true;
        });
      }),
    ]);
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  // ── Computed getters ──────────────────────────────────────────────────────

  /// Stock per variant, optionally scoped to the selected branch.
  Map<String, int> _variantStock(String? selectedBranchId) {
    final map = <String, int>{};
    for (final level in _levels) {
      if (selectedBranchId == null || level.branchId == selectedBranchId) {
        map[level.variantId] = (map[level.variantId] ?? 0) + level.quantity;
      }
    }
    return map;
  }

  /// Variants grouped by productId.
  Map<String, List<ProductVariantsTableData>> get _variantsMap {
    final map = <String, List<ProductVariantsTableData>>{};
    for (final v in _allVariants) {
      map.putIfAbsent(v.productId, () => []).add(v);
    }
    return map;
  }

  List<ProductsTableData> get _filteredProducts => _products
      .where((p) =>
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId)
      .where((p) =>
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  // ── Cart helper ───────────────────────────────────────────────────────────

  void _addToCart(
    ProductsTableData product,
    ProductVariantsTableData variant,
    double qty,
  ) {
    _cartService.addOrIncrement(
      variantId: variant.id,
      name: product.name,
      variant: variant.name == 'Default' ? '' : variant.name,
      unitPrice: variant.price,
      taxRate: product.tax,
      qty: qty,
    );
    final qtyLabel = product.sellBy == 'fraction'
        ? qty.toStringAsFixed(1)
        : qty.toInt().toString();
    final label = variant.name == 'Default'
        ? product.name
        : '${product.name} · ${variant.name}';
    if (mounted) {
      StatusSnack.show(
        context,
        type: StatusType.success,
        message: '$label × $qtyLabel added to cart',
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selectedBranchId =
        context.watch<BranchCubit>().state.selectedBranchId;

    return ListenableBuilder(
      listenable: _cartService,
      builder: (context, _) {
        final cartNotEmpty = _cartService.isNotEmpty;
        final subtotal =
            _cartService.items.fold(0.0, (s, i) => s + i.total);
        final cartTotal = (subtotal -
                _cartService.discountAmount(subtotal) +
                _cartService.items.fold(0.0, (s, i) => s + i.taxAmount))
            .clamp(0.0, double.infinity);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              SafeArea(
                child: !_productsLoaded
                    ? const _LoadingState()
                    : _buildContent(
                        selectedBranchId: selectedBranchId,
                        cartNotEmpty: cartNotEmpty,
                      ),
              ),
              _CartBar(
                cartService: _cartService,
                cartTotal: cartTotal,
                visible: cartNotEmpty,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent({
    required String? selectedBranchId,
    required bool cartNotEmpty,
  }) {
    final filtered = _filteredProducts;
    final items = filtered
        .map((p) => (p, _variantsMap[p.id] ?? <ProductVariantsTableData>[]))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, cartNotEmpty ? 80 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(
            hint: 'Search products...',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),
          ProductCategoryChips(
            categories: _categories,
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: (id) =>
                setState(() => _selectedCategoryId = id),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildGrid(filtered, items, _variantStock(selectedBranchId)),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    List<ProductsTableData> filtered,
    List<(ProductsTableData, List<ProductVariantsTableData>)> items,
    Map<String, int> variantStock,
  ) {
    if (_products.isEmpty) {
      return _EmptyProductsState(
        onAdd: () => context.push(AppRoutes.addProduct),
      );
    }
    if (filtered.isEmpty) {
      return _NoResultsState(
        onClear: () => setState(() {
          _searchQuery = '';
          _selectedCategoryId = null;
        }),
      );
    }
    return ProductGrid(
      items: items,
      variantStock: variantStock,
      onAddProduct: () => context.push(AppRoutes.addProduct),
      onAddToCart: _addToCart,
      onEditProduct: (p) => context.push(AppRoutes.editProduct, extra: p),
    );
  }
}

// ── Cart bar ──────────────────────────────────────────────────────────────────

class _CartBar extends StatelessWidget {
  final CartService cartService;
  final double cartTotal;
  final bool visible;

  const _CartBar({
    required this.cartService,
    required this.cartTotal,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 1.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: visible ? 1.0 : 0.0,
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductCartPage()),
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
                        '${cartService.itemCount}',
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
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── State widgets ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.brand,
          strokeWidth: 2.5,
        ),
      );
}

class _EmptyProductsState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyProductsState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
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
            style: AppTextStyles.body(context)
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onAdd,
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
}

class _NoResultsState extends StatelessWidget {
  final VoidCallback onClear;

  const _NoResultsState({required this.onClear});

  @override
  Widget build(BuildContext context) {
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
            style: AppTextStyles.body(context)
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onClear,
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
