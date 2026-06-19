enum DiscountType { percentage, fixed }

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

/// Subtotal/discount/tax/total for a set of cart items plus a discount.
///
/// Tax is computed on the POST-discount amount: a discount reduces what the
/// customer actually owes, and tax should apply to that — not to the full
/// pre-discount price. Each line's pre-discount tax is scaled by [taxRatio]
/// (the fraction of the subtotal surviving the discount) rather than
/// recomputed per line, so multi-rate carts stay correct without touching
/// [CartItem] itself.
class CartTotals {
  final double subtotal;
  final double discountAmount;
  final double tax;
  final double total;
  final double taxRatio;

  const CartTotals({
    required this.subtotal,
    required this.discountAmount,
    required this.tax,
    required this.total,
    required this.taxRatio,
  });

  /// This line's tax after the cart discount is applied — use this (not
  /// [CartItem.taxAmount]) when persisting a transaction item's tax, so the
  /// stored per-line tax sums back to [tax].
  double lineTax(CartItem item) => item.taxAmount * taxRatio;

  factory CartTotals.compute(
    List<CartItem> items,
    double Function(double subtotal) discountAmountFor,
  ) {
    final subtotal = items.fold(0.0, (s, i) => s + i.total);
    final discount = discountAmountFor(subtotal);
    final preDiscountTax = items.fold(0.0, (s, i) => s + i.taxAmount);
    final ratio = subtotal > 0 ? (subtotal - discount) / subtotal : 1.0;
    final tax = preDiscountTax * ratio;
    final total = (subtotal - discount + tax).clamp(0.0, double.infinity);
    return CartTotals(
      subtotal: subtotal,
      discountAmount: discount,
      tax: tax,
      total: total,
      taxRatio: ratio,
    );
  }
}