class ProductVariant {
  final String id;
  final String productId;
  final String businessId;
  final String name;
  final double price;
  final double? costPrice;
  final int stock;
  final double? stockDecimal;
  final String? sku;
  final String? barcode;
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
    this.stock = 0,
    this.stockDecimal,
    this.sku,
    this.barcode,
    this.isActive = true,
    this.trackStock = true,
    this.lowStockAlert,
  });
}
