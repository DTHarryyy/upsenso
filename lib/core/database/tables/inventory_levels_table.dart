import 'package:drift/drift.dart';

/// Per-branch stock levels for each product variant.
/// The [id] is a composite key formatted as "$variantId:${branchId ?? 'global'}".
/// This avoids nullable composite primary keys while keeping queries simple.
class InventoryLevelsTable extends Table {
  @override
  String get tableName => 'inventory_levels';

  /// Composite key: "$variantId:${branchId ?? 'global'}"
  TextColumn get id => text()();
  TextColumn get variantId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get businessId => text()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();

  /// 0=pendingUpload, 1=pendingUpdate, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
