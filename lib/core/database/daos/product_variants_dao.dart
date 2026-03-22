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

  /// Clear all variants (e.g., on logout).
  Future<void> clearAll() {
    return delete(productVariantsTable).go();
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
