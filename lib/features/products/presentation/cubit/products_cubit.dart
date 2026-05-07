import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/features/products/domain/entities/category.dart';
import 'package:pos/features/products/domain/entities/inventory_level.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/domain/entities/product_variant.dart';
import 'package:pos/features/products/domain/repositories/i_products_repository.dart';
import 'package:pos/features/products/presentation/cubit/products_state.dart';

/// Owns all reactive data streams for the Products screen.
///
/// Lifecycle:
/// 1. Call [startWatching] once (providing the current business ID).
/// 2. Call [setBranchFilter] whenever the selected branch changes.
/// 3. Call [setSearchQuery] / [setCategoryFilter] from the search bar / chips.
/// 4. Reads [ProductsLoaded.filteredProducts], [variantsMap], and [variantStock]
///    directly in the widget — no `setState` needed.
class ProductsCubit extends Cubit<ProductsState> {
  final IProductsRepository _repository;

  final List<StreamSubscription<dynamic>> _subs = [];

  // Mutable raw data — updated by each stream.
  var _products = <Product>[];
  var _variants = <ProductVariant>[];
  var _categories = <Category>[];
  var _levels = <InventoryLevel>[];

  // Filter state — copied into every emitted state.
  String? _selectedCategoryId;
  String _searchQuery = '';
  String? _branchId;

  // Tracks whether the products stream has emitted at least once.
  bool _productsReady = false;

  ProductsCubit({required IProductsRepository repository})
    : _repository = repository,
      super(const ProductsInitial());

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Begin listening to all four reactive data streams for [businessId].
  /// Safe to call multiple times; previous subscriptions are cancelled first.
  void startWatching(String businessId) {
    _cancelAll();
    _productsReady = false;
    emit(const ProductsLoading());

    _subs.addAll([
      _repository.watchInventoryLevels(businessId).listen((data) {
        _levels = data;
        _emitIfReady();
      }),
      _repository.watchVariants(businessId).listen((data) {
        _variants = data;
        _emitIfReady();
      }),
      _repository.watchCategories(businessId).listen((data) {
        _categories = data;
        // Auto-clear a category selection that no longer exists.
        if (_selectedCategoryId != null &&
            !data.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
        _emitIfReady();
      }),
      _repository.watchProducts(businessId).listen((data) {
        _products = data;
        _productsReady = true;
        _emitIfReady();
      }),
    ]);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _emitIfReady();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    _emitIfReady();
  }

  /// Update the branch used to scope variant stock counts.
  void setBranchFilter(String? branchId) {
    _branchId = branchId;
    _emitIfReady();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _emitIfReady() {
    if (!_productsReady || isClosed) return;
    emit(_buildLoaded());
  }

  ProductsLoaded _buildLoaded() {
    return ProductsLoaded(
      products: List.unmodifiable(_products),
      variants: List.unmodifiable(_variants),
      categories: List.unmodifiable(_categories),
      levels: List.unmodifiable(_levels),
      selectedCategoryId: _selectedCategoryId,
      searchQuery: _searchQuery,
      branchId: _branchId,
    );
  }

  void _cancelAll() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  @override
  Future<void> close() {
    _cancelAll();
    return super.close();
  }
}
