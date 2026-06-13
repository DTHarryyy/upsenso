import 'package:drift/drift.dart';

/// Bill-of-materials line for a recipe-based sellable variant.
/// Each row links one sellable [productVariantId] to one consumed
/// [ingredientVariantId] plus the quantity used per unit sold.
///
/// Ingredients are themselves product variants (products.type='ingredient'),
/// so consumption reuses the existing inventory_levels + stock_ledger stack.
/// No foreign keys — recipes stay valid if the recipes module is disabled or an
/// ingredient is soft-deleted. [ingredientName]/[unit] are denormalized so a
/// deleted ingredient still renders historically.
@DataClassName('RecipeLineRow')
class RecipeLinesTable extends Table {
  @override
  String get tableName => 'recipe_lines';

  TextColumn get id => text()();
  TextColumn get businessId => text()();

  /// The sellable variant that owns this recipe line.
  TextColumn get productVariantId => text()();

  /// The consumed ingredient's variant (products.type='ingredient').
  TextColumn get ingredientVariantId => text()();
  TextColumn get ingredientName => text()();

  /// Amount consumed per 1 unit sold, in the ingredient's own stock unit.
  RealColumn get quantity => real().withDefault(const Constant(0.0))();

  /// Unit of measure, denormalized from the ingredient (g, kg, ml, L, pcs).
  TextColumn get unit => text().nullable()();

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
