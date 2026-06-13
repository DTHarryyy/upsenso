import 'package:pos/core/database/app_database.dart';

class PurchaseOrderLine {
  final String id;
  final String purchaseOrderId;
  final String businessId;
  final String productId;
  final String variantId;
  final String productName;
  final String variantName;
  final String? sku;
  final double quantityOrdered;
  final double quantityReceived;
  final double unitCost;

  const PurchaseOrderLine({
    required this.id,
    required this.purchaseOrderId,
    required this.businessId,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    this.sku,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitCost,
  });

  factory PurchaseOrderLine.fromRow(PurchaseOrderLineRow row) =>
      PurchaseOrderLine(
        id: row.id,
        purchaseOrderId: row.purchaseOrderId,
        businessId: row.businessId,
        productId: row.productId,
        variantId: row.variantId,
        productName: row.productName,
        variantName: row.variantName,
        sku: row.sku,
        quantityOrdered: row.quantityOrdered,
        quantityReceived: row.quantityReceived,
        unitCost: row.unitCost,
      );

  double get totalCost => quantityOrdered * unitCost;
  double get remainingQty => (quantityOrdered - quantityReceived).clamp(0, double.infinity);
  bool get isFullyReceived => quantityReceived >= quantityOrdered;

  PurchaseOrderLine copyWith({
    double? quantityOrdered,
    double? quantityReceived,
    double? unitCost,
  }) => PurchaseOrderLine(
    id: id,
    purchaseOrderId: purchaseOrderId,
    businessId: businessId,
    productId: productId,
    variantId: variantId,
    productName: productName,
    variantName: variantName,
    sku: sku,
    quantityOrdered: quantityOrdered ?? this.quantityOrdered,
    quantityReceived: quantityReceived ?? this.quantityReceived,
    unitCost: unitCost ?? this.unitCost,
  );
}
