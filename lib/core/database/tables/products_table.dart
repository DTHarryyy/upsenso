import 'package:drift/drift.dart';

/// Local table for products. Mirrors the Supabase `products` schema.
/// Follows the offline-first sync-tracking pattern used by categories/branches.
class ProductsTable extends Table {
  @override
  String get tableName => 'products';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();

  RealColumn get tax => real().nullable()(); // tax percentage, e.g. 12.0 for 12%
  TextColumn get sellBy =>
      text().withDefault(const Constant('unit'))(); // 'unit' | 'fraction'

  BoolColumn get hasVariants =>
      boolean().withDefault(const Constant(false))();

  /// Local file path to the product image, stored in app documents directory.
  /// Null means no image. Offline-first — no network required.
  TextColumn get imagePath => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
