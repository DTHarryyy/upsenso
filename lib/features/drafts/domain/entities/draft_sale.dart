import 'package:equatable/equatable.dart';

/// A held / suspended sale (header only — items are loaded separately).
class DraftSale extends Equatable {
  final String id;
  final String? label;
  final String? customerName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final int itemCount;

  /// 'percentage' | 'fixed' | null — preserved so the discount restores on resume.
  final String? discountType;
  final double? discountValue;

  final String? branchId;
  final String cashierId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DraftSale({
    required this.id,
    this.label,
    this.customerName,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.itemCount,
    this.discountType,
    this.discountValue,
    this.branchId,
    required this.cashierId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    label,
    customerName,
    subtotal,
    taxAmount,
    discountAmount,
    totalAmount,
    itemCount,
    discountType,
    discountValue,
    branchId,
    cashierId,
    createdAt,
    updatedAt,
  ];
}
