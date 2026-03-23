class CartItem {
  final String variantId;
  final String name;
  final String variant;
  final double unitPrice;
  double qty = 1;

  CartItem({
    required this.variantId,
    required this.name,
    required this.variant,
    required this.unitPrice,
  });

  double get total => unitPrice * qty;
}