/// Input for a single line when creating or editing a PO.
class PoLineInput {
  final String productId;
  final String variantId;
  final String productName;
  final String variantName;
  final String? sku;
  final double quantityOrdered;
  final double unitCost;

  const PoLineInput({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    this.sku,
    required this.quantityOrdered,
    required this.unitCost,
  });

  /// Rounded to cents so floating-point noise (e.g. 0.1 * 3) never persists
  /// into the PO's stored total, and a stray "Infinity"/"NaN" typed into a
  /// qty/cost field can't propagate into the order total.
  double get totalCost {
    final raw = quantityOrdered * unitCost;
    if (!raw.isFinite) return 0.0;
    return (raw * 100).round() / 100;
  }
}

/// Input for receiving one line of a PO.
class ReceiveLineInput {
  final String lineId;
  final String variantId;
  final String productId;
  final double quantityToReceive;
  final double unitCost;

  const ReceiveLineInput({
    required this.lineId,
    required this.variantId,
    required this.productId,
    required this.quantityToReceive,
    required this.unitCost,
  });
}
