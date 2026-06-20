import 'package:drift/drift.dart';

/// Per-branch stock levels for each product variant.
/// The [id] is a composite key formatted as "$variantId:$branchId".
/// branchId is always a real branch UUID — no "global" rows allowed.
class InventoryLevelsTable extends Table {
  @override
  String get tableName => 'inventory_levels';

  /// Composite key: "$variantId:$branchId"
  TextColumn get id => text()();
  TextColumn get variantId => text()();

  /// NOT NULL — every stock row must belong to a specific branch.
  TextColumn get branchId => text()();
  TextColumn get businessId => text()();

  /// On-hand quantity for this variant+branch. Single decimal column — holds
  /// whole units and fractional quantities alike. Replaced the old int
  /// `quantity` + `quantity_decimal` pair in schema v46.
  RealColumn get quantity => real().withDefault(const Constant(0.0))();

  /// Per-branch low stock alert threshold.
  /// NULL means fall back to [product_variants.lowStockAlert] as the global default.
  IntColumn get lowStockAlertOverride => integer().nullable()();

  /// 0=pendingUpload, 1=pendingUpdate, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
