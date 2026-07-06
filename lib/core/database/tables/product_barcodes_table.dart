import 'package:drift/drift.dart';

/// Local table for product barcodes (normalized 1-to-many with variants).
/// Mirrors the Supabase `product_barcodes` table. A variant can carry several
/// codes; each `code` is unique per business. Replaces the single
/// `product_variants.barcode` column (which could only comma-join, breaking
/// exact-match scan resolution).
@DataClassName('ProductBarcodeRow')
class ProductBarcodesTable extends Table {
  @override
  String get tableName => 'product_barcodes';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get variantId => text()();
  TextColumn get code => text()();

  /// The primary/default code for the variant (first in the editor).
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  /// Soft delete — removals propagate to other devices via the delta-pull.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
