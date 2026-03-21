class Product {
  final String id;
  final String businessId;
  final String name;
  final String? categoryId;
  final String? sku;
  final String? barcode;
  final bool hasVariants;
  final bool isActive;

  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    this.categoryId,
    this.sku,
    this.barcode,
    this.hasVariants = false,
    this.isActive = true,
  });
}
