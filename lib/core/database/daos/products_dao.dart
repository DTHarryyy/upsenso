import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/products_table.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/products/domain/entities/product.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [ProductsTable])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  /// Insert a new product (syncStatus=0 = pendingUpload by default).
  Future<void> insertProduct(ProductsTableCompanion companion) {
    return into(productsTable).insert(companion);
  }

  /// Get all products for a business, ordered by name.
  Future<List<ProductsTableData>> getByBusinessId(String businessId) {
    return (select(productsTable)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Reactive stream of all products for a business.
  Stream<List<ProductsTableData>> watchByBusinessId(String businessId) {
    return (select(productsTable)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Get products filtered by category.
  Future<List<ProductsTableData>> getByCategoryId(String categoryId) {
    return (select(productsTable)
          ..where((t) => t.categoryId.equals(categoryId)))
        .get();
  }

  /// Reactive count of records that need syncing.
  Stream<int> watchPendingSyncCount() {
    final countExp = productsTable.id.count();
    final query = selectOnly(productsTable)
      ..addColumns([countExp])
      ..where(productsTable.syncStatus.isIn([0, 1, 4]));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  /// Records with pending sync: pendingUpload (0), pendingUpdate (1), failed (4).
  Future<List<ProductsTableData>> getPendingSync() {
    return (select(productsTable)
          ..where((t) => t.syncStatus.isIn([0, 1, 4])))
        .get();
  }

  /// Update sync status after a sync attempt.
  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) async {
    await (update(productsTable)..where((t) => t.id.equals(id))).write(
      ProductsTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// Hard-delete a product (after successful server deletion).
  Future<void> hardDelete(String id) {
    return (delete(productsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Upsert a product row pulled from Supabase (marks as synced).
  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(productsTable).insertOnConflictUpdate(
      ProductsTableCompanion.insert(
        id: row['id'] as String,
        businessId: row['business_id'] as String,
        categoryId: Value(row['category_id'] as String?),
        name: row['name'] as String,
        sku: Value(row['sku'] as String?),
        barcode: Value(row['barcode'] as String?),
        tax: Value((row['tax'] as num?)?.toDouble()),
        sellBy: Value((row['sell_by'] as String?) ?? 'unit'),
        hasVariants: Value((row['has_variants'] as bool?) ?? false),
        isActive: Value((row['is_active'] as bool?) ?? true),
        syncStatus: const Value(3), // synced
        lastSyncAttempt: Value(DateTime.now()),
      ),
    );
  }

  /// Clear all products (e.g., on logout).
  Future<void> clearAll() {
    return delete(productsTable).go();
  }

  /// Convert a Drift row to the domain entity.
  static Product toEntity(ProductsTableData data) {
    return Product(
      id: data.id,
      businessId: data.businessId,
      categoryId: data.categoryId,
      name: data.name,
      sku: data.sku,
      barcode: data.barcode,
      hasVariants: data.hasVariants,
      isActive: data.isActive,
    );
  }
}
