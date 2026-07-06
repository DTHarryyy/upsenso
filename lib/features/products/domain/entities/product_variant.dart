class ProductVariant {
  final String id;
  final String productId;
  final String businessId;
  final String name;
  final double price;
  final double? costPrice;

  /// Suggested retail price (SRP). Optional second sell tier — see checkout.
  final double? retailPrice;
  final double stock;
  final String? sku;
  final String? barcode;

  /// Unit of measure for weighed products (kg, g, L, ml). Null = per-piece.
  final String? unit;
  final bool isActive;
  final bool trackStock;
  final int? lowStockAlert;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.businessId,
    required this.name,
    required this.price,
    this.costPrice,
    this.retailPrice,
    this.stock = 0,
    this.sku,
    this.barcode,
    this.unit,
    this.isActive = true,
    this.trackStock = true,
    this.lowStockAlert,
  });
}
