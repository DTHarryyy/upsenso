class CartItem {
  final String variantId;
  final String name;
  final String variant;
  final double unitPrice;
  final double? taxRate; // e.g. 12.0 = 12% VAT; null = no tax
  double qty = 1;

  CartItem({
    required this.variantId,
    required this.name,
    required this.variant,
    required this.unitPrice,
    this.taxRate,
  });

  double get total => unitPrice * qty;
  double get taxAmount => unitPrice * qty * (taxRate ?? 0) / 100;
}