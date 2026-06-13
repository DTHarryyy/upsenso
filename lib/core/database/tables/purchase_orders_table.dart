import 'package:drift/drift.dart';

@DataClassName('PurchaseOrderRow')
class PurchaseOrdersTable extends Table {
  @override
  String get tableName => 'purchase_orders';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get branchId => text().nullable()();

  // Supplier — unconstrained; supplier may be deleted or module disabled.
  TextColumn get supplierId => text().nullable()();
  TextColumn get supplierName => text().nullable()();

  // Status: draft | submitted | approved | partially_received | received | cancelled
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get poNumber => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get expectedDelivery => dateTime().nullable()();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();

  TextColumn get createdById => text().nullable()();
  TextColumn get createdByName => text().nullable()();
  DateTimeColumn get submittedAt => dateTime().nullable()();
  DateTimeColumn get approvedAt => dateTime().nullable()();
  TextColumn get approvedById => text().nullable()();
  TextColumn get approvedByName => text().nullable()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get localUpdatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
