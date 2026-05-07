import 'package:equatable/equatable.dart';

/// Pure domain entity for a single line item in a sale transaction.
class SaleItem extends Equatable {
  final String transactionId;
  final String productName;
  final String variantName;
  final double qty;
  final double unitPrice;
  final double lineTotal;

  const SaleItem({
    required this.transactionId,
    required this.productName,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  @override
  List<Object?> get props => [
    transactionId,
    productName,
    variantName,
    qty,
    unitPrice,
    lineTotal,
  ];
}
