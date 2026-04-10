import 'package:drift/drift.dart';

/// Local table for product variants. Holds pricing/stock per variant.
/// Even simple (non-variant) products store one "Default" variant so that
/// price always lives at the variant level, matching the Supabase schema.
class ProductVariantsTable extends Table {
  @override
  String get tableName => 'product_variants';

  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get businessId => text()(); // denormalized for easy queries

  /// Variant label: "Default" for simple products, "Small"/"Large"/etc. for variants.
  TextColumn get name => text()();

  RealColumn get price => real().withDefault(const Constant(0.0))();
  RealColumn get costPrice => real().nullable()();
  /// Suggested retail price / SRP. Optional on all product types.
  RealColumn get retailPrice => real().nullable()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  RealColumn get stockDecimal => real().nullable()(); // used when sellBy == 'fraction'
  /// Optional threshold below which a low-stock alert should be triggered.
  IntColumn get lowStockAlert => integer().nullable()();
  BoolColumn get trackStock =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get trackExpiry =>
      boolean().withDefault(const Constant(false))();

  /// Expiry date for the variant. Stored as Unix epoch ms (Drift DateTimeColumn).
  /// Migrated from TEXT (ISO 8601) in schema v19.
  DateTimeColumn get expiryDate => dateTime().nullable()();
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
