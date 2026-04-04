import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/product_variants_table.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/products/domain/entities/product_variant.dart';

part 'product_variants_dao.g.dart';

@DriftAccessor(tables: [ProductVariantsTable])
class ProductVariantsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductVariantsDaoMixin {
  ProductVariantsDao(super.db);

  /// Insert a single variant (syncStatus=0 = pendingUpload by default).
  Future<void> insertVariant(ProductVariantsTableCompanion companion) {
    return into(productVariantsTable).insert(companion);
  }

  /// Batch insert multiple variants for a product.
  Future<void> insertVariants(
    List<ProductVariantsTableCompanion> companions,
  ) async {
    await batch((b) {
      for (final c in companions) {
        b.insert(productVariantsTable, c);
      }
    });
  }

  /// Get all variants for a product.
  Future<List<ProductVariantsTableData>> getByProductId(String productId) {
    return (select(productVariantsTable)
          ..where((t) => t.productId.equals(productId)))
        .get();
  }

  /// Reactive stream of variants for a product.
  Stream<List<ProductVariantsTableData>> watchByProductId(String productId) {
    return (select(productVariantsTable)
          ..where((t) => t.productId.equals(productId)))
        .watch();
  }

  /// Get all variants for a business (used during sync).
  Future<List<ProductVariantsTableData>> getByBusinessId(String businessId) {
    return (select(productVariantsTable)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
  }

  /// Reactive stream of all variants for a business (used in products listing).
  Stream<List<ProductVariantsTableData>> watchByBusinessId(String businessId) {
    return (select(productVariantsTable)
          ..where((t) => t.businessId.equals(businessId)))
        .watch();
  }

  /// Reactive count of records that need syncing.
  Stream<int> watchPendingSyncCount() {
    final countExp = productVariantsTable.id.count();
    final query = selectOnly(productVariantsTable)
      ..addColumns([countExp])
      ..where(productVariantsTable.syncStatus.isIn([0, 1, 4]));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  /// Records with pending sync: pendingUpload (0), pendingUpdate (1), failed (4).
  Future<List<ProductVariantsTableData>> getPendingSync() {
    return (select(productVariantsTable)
          ..where((t) => t.syncStatus.isIn([0, 1, 4])))
        .get();
  }

  /// Update sync status after a sync attempt.
  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) async {
    await (update(productVariantsTable)..where((t) => t.id.equals(id))).write(
      ProductVariantsTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// Delete all variants belonging to a product (used when editing a product).
  Future<void> deleteByProductId(String productId) {
    return (delete(productVariantsTable)
          ..where((t) => t.productId.equals(productId)))
        .go();
  }

  /// Hard-delete a variant (after successful server deletion).
  Future<void> hardDelete(String id) {
    return (delete(productVariantsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Upsert a variant row pulled from Supabase (marks as synced).
  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(productVariantsTable).insertOnConflictUpdate(
      ProductVariantsTableCompanion.insert(
        id: row['id'] as String,
        productId: row['product_id'] as String,
        businessId: row['business_id'] as String,
        name: row['name'] as String,
        price: Value((row['price'] as num?)?.toDouble() ?? 0.0),
        costPrice: Value((row['cost_price'] as num?)?.toDouble()),
        retailPrice: Value((row['retail_price'] as num?)?.toDouble()),
        stock: Value((row['stock'] as int?) ?? 0),
        sku: Value(row['sku'] as String?),
        barcode: Value(row['barcode'] as String?),
        trackExpiry: Value((row['track_expiry'] as bool?) ?? false),
        expiryDate: Value(row['expiry_date'] as String?),
        isActive: Value((row['is_active'] as bool?) ?? true),
        syncStatus: const Value(3), // synced
        lastSyncAttempt: Value(DateTime.now()),
      ),
    );
  }

  /// Find a single variant by barcode within a business.
  Future<ProductVariantsTableData?> getByBarcode(
    String barcode,
    String businessId,
  ) {
    return (select(productVariantsTable)
          ..where(
            (t) =>
                t.barcode.equals(barcode) & t.businessId.equals(businessId),
          ))
        .getSingleOrNull();
  }

  /// Clear all variants (e.g., on logout).
  Future<void> clearAll() {
    return delete(productVariantsTable).go();
  }

  /// Deduct [qty] from the variant's stock if stock tracking is enabled.
  /// - Unit products: deducts from [stock] (integer), clamped at 0.
  /// - Fraction products (stockDecimal != null): deducts from [stockDecimal].
  /// Marks the variant as pendingUpdate so it syncs to the server.
  Future<void> decrementStockIfTracked(String variantId, double qty) async {
    final variant = await (select(productVariantsTable)
          ..where((v) => v.id.equals(variantId)))
        .getSingleOrNull();

    if (variant == null || !variant.trackStock) return;

    if (variant.stockDecimal != null) {
      // Fraction / weight product
      final newStock =
          (variant.stockDecimal! - qty).clamp(0.0, double.maxFinite);
      await (update(productVariantsTable)
            ..where((v) => v.id.equals(variantId)))
          .write(
        ProductVariantsTableCompanion(
          stockDecimal: Value(newStock),
          syncStatus: const Value(1), // pendingUpdate
          localUpdatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // Unit product — clamp to [0, current stock]
      final newStock = (variant.stock - qty.round()).clamp(0, variant.stock);
      await (update(productVariantsTable)
            ..where((v) => v.id.equals(variantId)))
          .write(
        ProductVariantsTableCompanion(
          stock: Value(newStock),
          syncStatus: const Value(1), // pendingUpdate
          localUpdatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Get variants that are tracked and at or below their low-stock threshold.
  /// Also includes tracked items with stock = 0 even if no threshold is set.
  Future<List<ProductVariantsTableData>> getLowStockByBusinessId(
    String businessId,
  ) async {
    final rows = await (select(productVariantsTable)
          ..where(
            (v) =>
                v.businessId.equals(businessId) &
                v.trackStock.equals(true) &
                v.isActive.equals(true),
          ))
        .get();
    return rows.where((v) {
      final threshold = v.lowStockAlert;
      if (threshold != null) {
        // Has a threshold → alert when stock is at or below it
        return v.stock <= threshold;
      }
      // No threshold set → only alert when completely out of stock
      return v.stock <= 0;
    }).toList();
  }

  /// Convert a Drift row to the domain entity.
  static ProductVariant toEntity(ProductVariantsTableData data) {
    return ProductVariant(
      id: data.id,
      productId: data.productId,
      businessId: data.businessId,
      name: data.name,
      price: data.price,
      costPrice: data.costPrice,
      stock: data.stock,
      sku: data.sku,
      barcode: data.barcode,
      isActive: data.isActive,
    );
  }
}
