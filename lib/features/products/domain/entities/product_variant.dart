class ProductVariant {
  final String id;
  final String productId;
  final String businessId;
  final String name;
  final double price;
  final double? costPrice;
  final int stock;
  final String? sku;
  final String? barcode;
  final bool isActive;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.businessId,
    required this.name,
    required this.price,
    this.costPrice,
    this.stock = 0,
    this.sku,
    this.barcode,
    this.isActive = true,
  });
}
