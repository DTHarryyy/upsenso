import 'package:drift/drift.dart';

/// A recorded goods receipt against a purchase order (the GRN document).
/// One row per receiving event; line detail lives in goods_receipt_items.
@DataClassName('GoodsReceiptRow')
class GoodsReceiptsTable extends Table {
  @override
  String get tableName => 'goods_receipts';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get purchaseOrderId => text()();
  TextColumn get branchId => text()();
  TextColumn get receiptNumber => text()();
  TextColumn get receivedById => text().nullable()();
  TextColumn get receivedByName => text().nullable()();
  TextColumn get notes => text().nullable()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
