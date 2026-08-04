import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/products/checkout/product_cart_page.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/domain/entities/product_variant.dart';
import 'package:pos/features/products/domain/repositories/i_products_repository.dart';
import 'package:pos/features/products/presentation/cubit/products_cubit.dart';
import 'package:pos/features/products/presentation/cubit/products_state.dart';
import 'package:pos/features/products/widgets/product_category_chips.dart';
import 'package:pos/features/products/widgets/product_grid.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _cartService = sl<CartService>();
  late final ProductsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ProductsCubit(repository: sl<IProductsRepository>());
    // Defer one frame so BLoC state is readable from context.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWatching());
  }

  void _startWatching() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    final businessId = authState is AuthAuthenticated
        ? authState.user.businessId
        : null;
    if (businessId == null) return;

    final branchId = context.read<BranchCubit>().state.selectedBranchId;
    _cubit
      ..startWatching(businessId)
      ..setBranchFilter(branchId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _addToCart(Product product, ProductVariant variant, double qty) {
    final unit = product.sellBy == 'fraction' ? variant.unit : null;
    _cartService.addOrIncrement(
      variantId: variant.id,
      name: product.name,
      variant: variant.name == 'Default' ? '' : variant.name,
      unitPrice: variant.price,
      taxRate: product.tax,
      unit: unit,
      qty: qty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<BranchCubit, BranchState>(
        listener: (context, branchState) =>
            _cubit.setBranchFilter(branchState.selectedBranchId),
        child: ListenableBuilder(
          listenable: _cartService,
          builder: (context, _) {
            final cartNotEmpty = _cartService.isNotEmpty;
            final cartTotal = _cartService.computeTotals().total;

            // Gate add/edit and cart on the granted PERMISSIONS, not a hardcoded
            // role string — so an override granting products.create /
            // products.edit (or pos.use) actually surfaces the affordances.
            // Computed once here so the grid and the cart bar (outside the inner
            // BlocBuilder) share it; the server enforces the writes regardless.
            final perms = sl<PermissionService>();
            final canAddEditProduct = perms.can(PermissionKeys.productsCreate) ||
                perms.can(PermissionKeys.productsEdit);
            final canAddToCart = perms.can(PermissionKeys.posUse);

            return Scaffold(
              backgroundColor: AppColors.background,
              body: Stack(
                children: [
                  SafeArea(
                    child: BlocBuilder<ProductsCubit, ProductsState>(
                      builder: (context, state) => _buildContent(
                        context,
                        state: state,
                        cartNotEmpty: cartNotEmpty,
                        canAddEditProduct: canAddEditProduct,
                        canAddToCart: canAddToCart,
                      ),
                    ),
                  ),
                  // Cart bar is suppressed entirely for inventory staff —
                  // they manage stock, not sales.
                  _CartBar(
                    cartService: _cartService,
                    cartTotal: cartTotal,
                    visible: cartNotEmpty && canAddToCart,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required ProductsState state,
    required bool cartNotEmpty,
    required bool canAddEditProduct,
    required bool canAddToCart,
  }) {
    if (state is ProductsInitial || state is ProductsLoading) {
      return const _LoadingState();
    }

    if (state is! ProductsLoaded) return const SizedBox.shrink();

    final filtered = state.filteredProducts;
    final variantsMap = state.variantsMap;
    final items = filtered
        .map((p) => (p, variantsMap[p.id] ?? <ProductVariant>[]))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, cartNotEmpty ? 80 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(
            hint: 'Search products...',
            onChanged: (v) => _cubit.setSearchQuery(v),
          ),
          const SizedBox(height: 12),
          ProductCategoryChips(
            categories: state.categories,
            selectedCategoryId: state.selectedCategoryId,
            onCategorySelected: (id) => _cubit.setCategoryFilter(id),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildGrid(
              context,
              state,
              filtered,
              items,
              canAddEditProduct: canAddEditProduct,
              canAddToCart: canAddToCart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    ProductsLoaded state,
    List<Product> filtered,
    List<(Product, List<ProductVariant>)> items, {
    required bool canAddEditProduct,
    required bool canAddToCart,
  }) {
    if (state.products.isEmpty) {
      return _EmptyProductsState(
        onAdd: canAddEditProduct
            ? () => context.push(AppRoutes.addProduct)
            : null,
      );
    }
    if (filtered.isEmpty) {
      return _NoResultsState(
        onClear: () => _cubit
          ..setSearchQuery('')
          ..setCategoryFilter(null),
      );
    }
    return ProductGrid(
      items: items,
      variantStock: state.variantStock,
      onAddProduct: canAddEditProduct
          ? () => context.push(AppRoutes.addProduct)
          : null,
      onAddToCart: canAddToCart ? _addToCart : null,
      onEditProduct: canAddEditProduct
          ? (p) => context.push(AppRoutes.editProduct, extra: p)
          : null,
    );
  }
}

// ── Cart bar ──────────────────────────────────────────────────────────────────

// Renders its pill into the root Overlay instead of this page's own Stack, so
// it paints above the outer shell's AI assistant FAB — Scaffold composites
// floatingActionButton above the whole body, so no local Stack ordering can
// out-rank it.
class _CartBar extends StatefulWidget {
  final CartService cartService;
  final double cartTotal;
  final bool visible;

  const _CartBar({
    required this.cartService,
    required this.cartTotal,
    required this.visible,
  });

  @override
  State<_CartBar> createState() => _CartBarState();
}

class _CartBarState extends State<_CartBar> {
  final _controller = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    // Safe here only because the portal isn't attached yet, so this records a
    // z-order index instead of calling setState. The pill then stays mounted
    // and animates itself in and out via `visible` below.
    _controller.show();
  }

  Widget _buildPill(BuildContext context) {
    // StatefulShellRoute.indexedStack keeps inactive tabs alive, wrapped in
    // Offstage/TickerMode(enabled: false). The overlay child is parented to
    // the root theater, so Offstage never hides it — without this guard the
    // pill would linger over other tabs while the cart is non-empty.
    final visible = widget.visible && TickerMode.valuesOf(context).enabled;
    // viewPadding, not padding: ancestors have already consumed the latter.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Positioned(
      left: 16,
      right: 16,
      // AppBottomNav is 60px tall plus its own bottom safe-area padding; a
      // root-overlay Positioned isn't clipped above it like Scaffold.body
      // was, so that clearance has to be added back explicitly.
      bottom: 60 + bottomInset + 12,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          offset: visible ? Offset.zero : const Offset(0, 1.5),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: visible ? 1.0 : 0.0,
            child: GestureDetector(
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const ProductCartPage()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.cartService.itemCount}',
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
                      ProductCartPage.fmtPrice(widget.cartTotal),
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

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _controller,
      // Root overlay puts the pill above the shell Scaffold's AI assistant
      // FAB, while still sitting below anything pushed later (bottom sheets,
      // ProductCartPage).
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: _buildPill,
    );
  }
}

// ── State widgets ─────────────────────────────────────────────────────────────

class _LoadingState extends StatefulWidget {
  const _LoadingState();

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final shimmerPos = -0.3 + 1.6 * _ctrl.value;

        Widget box({double? width, double height = 14, double radius = 8}) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                colors: const [
                  Color(0xFFE2E8F0),
                  Color(0xFFECF0F6),
                  Color(0xFFF5F8FC),
                  Color(0xFFECF0F6),
                  Color(0xFFE2E8F0),
                ],
                stops: [
                  (shimmerPos - 0.4).clamp(0.0, 1.0),
                  (shimmerPos - 0.2).clamp(0.0, 1.0),
                  shimmerPos.clamp(0.0, 1.0),
                  (shimmerPos + 0.2).clamp(0.0, 1.0),
                  (shimmerPos + 0.4).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        }

        Widget productCardSkeleton() {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: box(radius: 8)),
                const SizedBox(height: 6),
                box(radius: 5),
                const SizedBox(height: 4),
                box(width: 64, height: 11, radius: 5),
                const SizedBox(height: 6),
                box(height: 26, radius: 6),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar skeleton
              box(height: 44, radius: 12),
              const SizedBox(height: 12),
              // Category chips skeleton
              SizedBox(
                height: 34,
                child: Row(
                  children: [
                    box(width: 72, height: 32, radius: 16),
                    const SizedBox(width: 8),
                    box(width: 90, height: 32, radius: 16),
                    const SizedBox(width: 8),
                    box(width: 80, height: 32, radius: 16),
                    const SizedBox(width: 8),
                    box(width: 68, height: 32, radius: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Product grid skeleton
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final int cols = constraints.maxWidth >= 1024
                        ? 7
                        : constraints.maxWidth >= 600
                        ? 5
                        : 3;
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: cols * 4,
                      itemBuilder: (_, _) => productCardSkeleton(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  final VoidCallback? onAdd;

  const _EmptyProductsState({this.onAdd});

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
            onAdd != null
                ? 'Tap "Add Product" to get started'
                : 'No products have been added yet',
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (onAdd != null)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, color: AppColors.brand),
              label: Text(
                'Add Product',
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.brand, fontWeight: FontWeight.w600),
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
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Clear filters',
              style: AppTextStyles.body(
                context,
              ).copyWith(color: AppColors.brand, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
