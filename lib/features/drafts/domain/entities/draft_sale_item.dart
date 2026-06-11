import 'package:equatable/equatable.dart';

/// A single line in a held / suspended sale. Pure domain entity, decoupled
/// from Drift-generated types and from the POS [CartItem].
class DraftSaleItem extends Equatable {
  final String variantId;
  final String productName;
  final String variantName;
  final double unitPrice;
  final double? taxRate;
  final double qty;
  final double lineTotal;
  final double lineTax;

  const DraftSaleItem({
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    this.taxRate,
    required this.qty,
    required this.lineTotal,
    required this.lineTax,
  });

  @override
  List<Object?> get props => [
    variantId,
    productName,
    variantName,
    unitPrice,
    taxRate,
    qty,
    lineTotal,
    lineTax,
  ];
}
