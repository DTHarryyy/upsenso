import 'package:equatable/equatable.dart';

enum StockStatus { inStock, warning, lowStock, notTracked, recipe, service }

class BranchInfo extends Equatable {
  final String id;
  final String name;

  const BranchInfo({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class InventoryItem extends Equatable {
  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final String? sku;

  /// Stock keyed by branchId. A null key means "global / no branch".
  final Map<String, int> stockByBranch;

  /// Total stock across all branches (or from product_variants.stock when
  /// no per-branch entries exist yet).
  final int totalStock;

  /// Reorder threshold from product_variants.lowStockAlert (0 when unset).
  final int reorderLevel;

  /// Whether stock is tracked for this variant. When false, stock numbers are
  /// meaningless and the item should be displayed as "Not Tracked".
  final bool trackStock;

  /// 'product_stock' | 'recipe' | 'service'
  final String trackingMethod;

  const InventoryItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    this.sku,
    required this.stockByBranch,
    required this.totalStock,
    required this.reorderLevel,
    this.trackStock = true,
    this.trackingMethod = 'product_stock',
  });

  bool get isRecipe => trackingMethod == 'recipe';
  bool get isService => trackingMethod == 'service';

  StockStatus get status {
    if (isService) return StockStatus.service;
    if (isRecipe) return StockStatus.recipe;
    if (!trackStock) return StockStatus.notTracked;
    if (reorderLevel <= 0) {
      return totalStock <= 0 ? StockStatus.lowStock : StockStatus.inStock;
    }
    if (totalStock <= reorderLevel) return StockStatus.lowStock;
    if (totalStock <= (reorderLevel * 1.5).ceil()) return StockStatus.warning;
    return StockStatus.inStock;
  }

  @override
  List<Object?> get props => [variantId, stockByBranch, totalStock, trackStock, trackingMethod];
}

class InventoryData extends Equatable {
  final List<InventoryItem> items;
  final List<BranchInfo> branches;

  const InventoryData({required this.items, required this.branches});

  static const empty = InventoryData(items: [], branches: []);

  int get totalProducts => items.length;
  int get trackedCount =>
      items.where((i) => i.status == StockStatus.inStock || i.status == StockStatus.warning || i.status == StockStatus.lowStock).length;
  int get notTrackedCount =>
      items.where((i) => i.status == StockStatus.notTracked).length;
  int get recipeCount => items.where((i) => i.isRecipe).length;
  int get serviceCount => items.where((i) => i.isService).length;
  int get lowStockCount =>
      items.where((i) => i.status == StockStatus.lowStock).length;
  int get warningCount =>
      items.where((i) => i.status == StockStatus.warning).length;

  @override
  List<Object?> get props => [items, branches];
}
