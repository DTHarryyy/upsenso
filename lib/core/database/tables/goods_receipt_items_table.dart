import 'package:drift/drift.dart';

/// A single line of a goods receipt — how much of a PO line was received in one
/// receiving event, at what unit cost.
@DataClassName('GoodsReceiptItemRow')
class GoodsReceiptItemsTable extends Table {
  @override
  String get tableName => 'goods_receipt_items';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get goodsReceiptId => text()();
  TextColumn get purchaseOrderLineId => text()();
  TextColumn get variantId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get quantityReceived => real().withDefault(const Constant(0.0))();
  RealColumn get unitCost => real().withDefault(const Constant(0.0))();

  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
