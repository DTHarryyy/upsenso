import 'package:pos/core/database/app_database.dart';

/// A recorded goods-receipt event against a PO (the GRN header).
class GoodsReceipt {
  final String id;
  final String purchaseOrderId;
  final String receiptNumber;
  final String? receivedByName;
  final String? notes;
  final DateTime receivedAt;

  const GoodsReceipt({
    required this.id,
    required this.purchaseOrderId,
    required this.receiptNumber,
    this.receivedByName,
    this.notes,
    required this.receivedAt,
  });

  factory GoodsReceipt.fromRow(GoodsReceiptRow r) => GoodsReceipt(
    id: r.id,
    purchaseOrderId: r.purchaseOrderId,
    receiptNumber: r.receiptNumber,
    receivedByName: r.receivedByName,
    notes: r.notes,
    receivedAt: r.receivedAt,
  );
}
