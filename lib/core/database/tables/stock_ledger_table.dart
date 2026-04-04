import 'package:drift/drift.dart';

/// Immutable history of every stock movement.
/// All stock changes MUST go through this table — direct writes to
/// inventory_levels are done by the repository after inserting here.
class StockLedgerTable extends Table {
  @override
  String get tableName => 'stock_ledger';

  TextColumn get id => text()();
  TextColumn get variantId => text()();
  TextColumn get productId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get businessId => text()();

  /// 'IN' for incoming stock, 'OUT' for outgoing stock.
  TextColumn get changeType => text()();

  /// Always a positive integer (direction is determined by [changeType]).
  IntColumn get quantity => integer()();

  /// One of: 'Restock', 'Damage', 'Transfer', 'Adjustment'
  TextColumn get reason => text()();
  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 0=pendingUpload, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
