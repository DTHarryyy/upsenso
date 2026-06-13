/// A single ingredient that can be consumed by recipe-based products.
///
/// Backed by a product row (type='ingredient') and one Default variant.
/// Reuses the existing inventory_levels + stock_ledger stack.
class Ingredient {
  final String id; // variant id (Default variant of the ingredient product)
  final String productId;
  final String businessId;
  final String name;
  final String? unit; // g, kg, ml, L, pcs …
  final double stock; // current stock across selected branch
  final double? costPrice; // cost per stock unit — used for live recipe costing
  final int? lowStockAlert;
  final bool isActive;

  const Ingredient({
    required this.id,
    required this.productId,
    required this.businessId,
    required this.name,
    this.unit,
    required this.stock,
    this.costPrice,
    this.lowStockAlert,
    required this.isActive,
  });
}
