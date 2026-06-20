import 'package:equatable/equatable.dart';

/// Pure domain entity for a completed sale transaction.
/// Decouples the presentation layer from Drift-generated table types.
class SaleTransaction extends Equatable {
  final String id;
  final String? invoiceNumber;
  final DateTime createdAt;
  final double totalAmount;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double? amountReceived;
  final double? changeDue;
  final String paymentMethod;
  final String? customerName;
  final String cashierId;
  final String? cashierName;
  final String? branchId;
  final int itemCount;
  final String status;
  final double refundedAmount;

  const SaleTransaction({
    required this.id,
    this.invoiceNumber,
    required this.createdAt,
    required this.totalAmount,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    this.amountReceived,
    this.changeDue,
    required this.paymentMethod,
    this.customerName,
    required this.cashierId,
    this.cashierName,
    this.branchId,
    required this.itemCount,
    this.status = 'completed',
    this.refundedAmount = 0.0,
  });

  bool get isRefunded => status == 'refunded';
  bool get isPartiallyRefunded => status == 'partially_refunded';
  double get netAmount => totalAmount - refundedAmount;

  @override
  List<Object?> get props => [
    id,
    invoiceNumber,
    createdAt,
    totalAmount,
    subtotal,
    taxAmount,
    discountAmount,
    amountReceived,
    changeDue,
    paymentMethod,
    customerName,
    cashierId,
    cashierName,
    branchId,
    itemCount,
    status,
    refundedAmount,
  ];
}
