import 'package:drift/drift.dart';

@DataClassName('PurchaseOrderLineRow')
class PurchaseOrderLinesTable extends Table {
  @override
  String get tableName => 'purchase_order_lines';

  TextColumn get id => text()();
  // No FK constraint — PO may belong to a disabled module or be deleted.
  TextColumn get purchaseOrderId => text()();
  TextColumn get businessId => text()();

  // Product/variant — unconstrained; names denormalized for historical stability.
  TextColumn get productId => text()();
  TextColumn get variantId => text()();
  TextColumn get productName => text()();
  TextColumn get variantName => text()();
  TextColumn get sku => text().nullable()();

  RealColumn get quantityOrdered => real().withDefault(const Constant(0.0))();
  RealColumn get quantityReceived => real().withDefault(const Constant(0.0))();
  RealColumn get unitCost => real().withDefault(const Constant(0.0))();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get localUpdatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
