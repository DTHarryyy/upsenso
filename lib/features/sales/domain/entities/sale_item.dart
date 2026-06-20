import 'package:equatable/equatable.dart';

/// Pure domain entity for a single line item in a sale transaction.
class SaleItem extends Equatable {
  final String id;
  final String transactionId;
  final String variantId;
  final String productName;
  final String variantName;
  final double qty;
  final double unitPrice;
  final double lineTotal;
  final double refundedQty;

  /// Whether refunding this line would actually move inventory — false for
  /// `service`-type products and for `product_stock` variants with stock
  /// tracking turned off. Lets the refund UI hide the "restock" toggle when
  /// it would be a no-op rather than offer a control that silently does
  /// nothing. `recipe`-tracked items are always true: their ingredients move
  /// regardless of the finished variant's own trackStock flag.
  final bool isStockTracked;

  const SaleItem({
    required this.id,
    required this.transactionId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    this.refundedQty = 0.0,
    this.isStockTracked = true,
  });

  /// How much of this line is still eligible for refund.
  double get remainingQty => (qty - refundedQty).clamp(0.0, qty);

  @override
  List<Object?> get props => [
    id,
    transactionId,
    variantId,
    productName,
    variantName,
    qty,
    unitPrice,
    lineTotal,
    refundedQty,
    isStockTracked,
  ];
}
