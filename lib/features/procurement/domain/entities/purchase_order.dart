import 'package:pos/core/database/app_database.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order_line.dart';

class PurchaseOrder {
  final String id;
  final String businessId;
  final String? branchId;
  final String? supplierId;
  final String? supplierName;
  final PoStatus status;
  final String poNumber;
  final String? notes;
  final DateTime? expectedDelivery;
  final double discount;
  final double shipping;
  final double totalAmount;
  final String? createdById;
  final String? createdByName;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String? approvedById;
  final String? approvedByName;
  final DateTime createdAt;
  final List<PurchaseOrderLine> lines;

  /// Aggregate ordered/received quantities across all lines. Populated by the
  /// list stream (which doesn't carry full line data) so the list card can show
  /// the same receiving progress as the detail page. Default 0 when unknown.
  final double quantityOrdered;
  final double quantityReceived;

  const PurchaseOrder({
    required this.id,
    required this.businessId,
    this.branchId,
    this.supplierId,
    this.supplierName,
    required this.status,
    required this.poNumber,
    this.notes,
    this.expectedDelivery,
    this.discount = 0,
    this.shipping = 0,
    required this.totalAmount,
    this.createdById,
    this.createdByName,
    this.submittedAt,
    this.approvedAt,
    this.approvedById,
    this.approvedByName,
    required this.createdAt,
    this.lines = const [],
    this.quantityOrdered = 0,
    this.quantityReceived = 0,
  });

  /// Fraction of ordered quantity that has been received (0..1).
  double get receivedFraction => quantityOrdered <= 0
      ? 0
      : (quantityReceived / quantityOrdered).clamp(0.0, 1.0);

  factory PurchaseOrder.fromRow(
    PurchaseOrderRow row, {
    List<PurchaseOrderLine> lines = const [],
    double quantityOrdered = 0,
    double quantityReceived = 0,
  }) => PurchaseOrder(
    id: row.id,
    businessId: row.businessId,
    branchId: row.branchId,
    supplierId: row.supplierId,
    supplierName: row.supplierName,
    status: PoStatus.fromString(row.status),
    poNumber: row.poNumber,
    notes: row.notes,
    expectedDelivery: row.expectedDelivery,
    discount: row.discount,
    shipping: row.shipping,
    totalAmount: row.totalAmount,
    createdById: row.createdById,
    createdByName: row.createdByName,
    submittedAt: row.submittedAt,
    approvedAt: row.approvedAt,
    approvedById: row.approvedById,
    approvedByName: row.approvedByName,
    createdAt: row.createdAt,
    lines: lines,
    quantityOrdered: quantityOrdered,
    quantityReceived: quantityReceived,
  );

  PurchaseOrder copyWith({
    PoStatus? status,
    List<PurchaseOrderLine>? lines,
    double? totalAmount,
  }) => PurchaseOrder(
    id: id,
    businessId: businessId,
    branchId: branchId,
    supplierId: supplierId,
    supplierName: supplierName,
    status: status ?? this.status,
    poNumber: poNumber,
    notes: notes,
    expectedDelivery: expectedDelivery,
    discount: discount,
    shipping: shipping,
    totalAmount: totalAmount ?? this.totalAmount,
    createdById: createdById,
    createdByName: createdByName,
    submittedAt: submittedAt,
    approvedAt: approvedAt,
    approvedById: approvedById,
    approvedByName: approvedByName,
    createdAt: createdAt,
    lines: lines ?? this.lines,
  );
}
