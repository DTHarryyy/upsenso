import 'package:equatable/equatable.dart';
import 'package:pos/core/database/app_database.dart';

// Sentinel used to distinguish "not passed" from `null` in copyWith.
const _sentinel = Object();

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

/// All four reactive data streams have emitted at least once.
class ProductsLoaded extends ProductsState {
  final List<ProductsTableData> products;
  final List<ProductVariantsTableData> variants;
  final List<CategoriesTableData> categories;
  final List<InventoryLevelsTableData> levels;

  /// Active category filter, `null` means "all categories".
  final String? selectedCategoryId;
  final String searchQuery;

  /// Active branch filter used to scope variant stock counts.
  final String? branchId;

  const ProductsLoaded({
    required this.products,
    required this.variants,
    required this.categories,
    required this.levels,
    this.selectedCategoryId,
    this.searchQuery = '',
    this.branchId,
  });

  // ── Computed properties ────────────────────────────────────────────────────

  /// Variants keyed by product ID, ready for O(1) lookup in the grid.
  Map<String, List<ProductVariantsTableData>> get variantsMap {
    final map = <String, List<ProductVariantsTableData>>{};
    for (final v in variants) {
      map.putIfAbsent(v.productId, () => []).add(v);
    }
    return map;
  }

  /// Total stock per variant, optionally scoped to [branchId].
  Map<String, int> get variantStock {
    final map = <String, int>{};
    for (final level in levels) {
      if (branchId == null || level.branchId == branchId) {
        map[level.variantId] = (map[level.variantId] ?? 0) + level.quantity;
      }
    }
    return map;
  }

  /// Products passing the active category and search filters.
  List<ProductsTableData> get filteredProducts => products
      .where(
        (p) => selectedCategoryId == null || p.categoryId == selectedCategoryId,
      )
      .where(
        (p) =>
            searchQuery.isEmpty ||
            p.name.toLowerCase().contains(searchQuery.toLowerCase()),
      )
      .toList();

  @override
  List<Object?> get props => [
    products,
    variants,
    categories,
    levels,
    selectedCategoryId,
    searchQuery,
    branchId,
  ];

  ProductsLoaded copyWith({
    List<ProductsTableData>? products,
    List<ProductVariantsTableData>? variants,
    List<CategoriesTableData>? categories,
    List<InventoryLevelsTableData>? levels,
    Object? selectedCategoryId = _sentinel,
    String? searchQuery,
    Object? branchId = _sentinel,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      variants: variants ?? this.variants,
      categories: categories ?? this.categories,
      levels: levels ?? this.levels,
      selectedCategoryId: selectedCategoryId == _sentinel
          ? this.selectedCategoryId
          : selectedCategoryId as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      branchId: branchId == _sentinel ? this.branchId : branchId as String?,
    );
  }
}
