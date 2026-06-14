import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/inventory_levels_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'inventory_levels_dao.g.dart';

extension InventoryLevelQuantity on InventoryLevelsTableData {
  // A 0 decimal means "unset" — never let it mask the integer quantity.
  double get effectiveQuantity =>
      (quantityDecimal != null && quantityDecimal != 0)
          ? quantityDecimal!
          : quantity.toDouble();
}

@DriftAccessor(tables: [InventoryLevelsTable])
class InventoryLevelsDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryLevelsDaoMixin {
  InventoryLevelsDao(super.db);

  /// Builds the composite PK string. branchId is now non-nullable — every
  /// inventory row must belong to a real branch (no "global" rows allowed).
  static String makeId(String variantId, String branchId) =>
      '$variantId:$branchId';

  /// Get all inventory level rows for a business.
  Future<List<InventoryLevelsTableData>> getByBusinessId(String businessId) {
    return (select(inventoryLevelsTable)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
  }

  /// Watch all inventory level rows for a business (reactive).
  Stream<List<InventoryLevelsTableData>> watchByBusinessId(String businessId) {
    return (select(inventoryLevelsTable)
          ..where((t) => t.businessId.equals(businessId)))
        .watch();
  }

  /// Get the level row for a specific variant + branch combo.
  Future<InventoryLevelsTableData?> getLevel(
    String variantId,
    String branchId,
  ) {
    final id = makeId(variantId, branchId);
    return (select(inventoryLevelsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Upsert a level row. Creates it if missing, replaces it if present.
  Future<void> upsertLevel({
    required String variantId,
    required String branchId,
    required String businessId,
    required int quantity,
    double? quantityDecimal,
  }) {
    final id = makeId(variantId, branchId);
    return into(inventoryLevelsTable).insertOnConflictUpdate(
      InventoryLevelsTableCompanion.insert(
        id: id,
        variantId: variantId,
        branchId: branchId,
        businessId: businessId,
        quantity: Value(quantity),
        quantityDecimal: Value(quantityDecimal),
        syncStatus: const Value(1), // pendingUpdate
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Atomically adjust the quantity for a variant+branch by [delta].
  ///
  /// For unit products, pass [delta] (integer delta).
  /// For fractional products (sellBy='fraction'), pass [deltaDecimal] instead;
  /// [delta] should be 0 in that case.
  ///
  /// A branch with no existing row starts from 0 — there is no global-stock
  /// seeding. Callers must NOT pass product_variants.stock as a seed.
  Future<void> adjustQuantity({
    required String variantId,
    required String branchId,
    required String businessId,
    required int delta,
    double? deltaDecimal,
  }) async {
    final id = makeId(variantId, branchId);
    final existing = await (select(inventoryLevelsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    final int nextQty;
    final double? nextDecimal;

    if (deltaDecimal != null) {
      // Fractional product path. Seed from the EFFECTIVE quantity so a row that
      // until now tracked whole units (quantityDecimal still null) doesn't lose
      // its existing stock the first time it receives a fractional movement.
      final currentDecimal = existing?.effectiveQuantity ?? 0.0;
      nextDecimal = (currentDecimal + deltaDecimal).clamp(0.0, 999999.0);
      // Keep the integer column as a rounded mirror so int-only readers and the
      // variant-total recompute stay consistent with the decimal source.
      nextQty = nextDecimal.round().clamp(0, 999999);
    } else {
      // Unit product path
      final current = existing?.quantity ?? 0;
      nextQty = (current + delta).clamp(0, 999999);
      nextDecimal = existing?.quantityDecimal;
    }

    await into(inventoryLevelsTable).insertOnConflictUpdate(
      InventoryLevelsTableCompanion.insert(
        id: id,
        variantId: variantId,
        branchId: branchId,
        businessId: businessId,
        quantity: Value(nextQty),
        quantityDecimal: Value(nextDecimal),
        syncStatus: const Value(1),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Returns the effective low stock threshold for a variant+branch.
  /// Uses the per-branch override when set, falls back to the global [defaultThreshold].
  int getEffectiveLowStockAlert(
    InventoryLevelsTableData? level,
    int? defaultThreshold,
  ) {
    return level?.lowStockAlertOverride ?? defaultThreshold ?? 0;
  }

  /// Get all level rows for a specific variant across all branches.
  Future<List<InventoryLevelsTableData>> getByVariantId(String variantId) {
    return (select(inventoryLevelsTable)
          ..where((t) => t.variantId.equals(variantId)))
        .get();
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = inventoryLevelsTable.id.count();
    final query = selectOnly(inventoryLevelsTable)
      ..addColumns([countExp])
      ..where(inventoryLevelsTable.syncStatus.isIn([
            SyncStatus.pendingUpload.toInt(),
            SyncStatus.pendingUpdate.toInt(),
            SyncStatus.failed.toInt(),
          ]));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<InventoryLevelsTableData>> getPendingSync() {
    return (select(inventoryLevelsTable)
          ..where((t) => t.syncStatus.isIn([
                SyncStatus.pendingUpload.toInt(),
                SyncStatus.pendingUpdate.toInt(),
                SyncStatus.failed.toInt(),
              ])))
        .get();
  }

  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) {
    return (update(inventoryLevelsTable)..where((t) => t.id.equals(id))).write(
      InventoryLevelsTableCompanion(
        syncStatus: Value(status.toInt()),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) async {
    // The app writes the variant uuid into product_variant_id and leaves the
    // legacy text variant_id null — prefer it, or every pull crashes on null.
    final variantId =
        (row['product_variant_id'] ?? row['variant_id']) as String;
    final branchId = row['branch_id'] as String;
    final id = makeId(variantId, branchId);

    // Never overwrite a row that has local changes not yet pushed to the
    // server. If we did, a failed push followed by a pull would silently
    // discard the user's offline edits.
    final existing = await (select(inventoryLevelsTable)
            ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (existing != null &&
        existing.syncStatus != SyncStatus.synced.toInt()) {
      return;
    }

    // 0 means "no decimal" — legacy unit rows pushed 0.0; keep it from masking quantity.
    final rawDecimal = (row['quantity_decimal'] as num?)?.toDouble();
    final decimal = (rawDecimal == null || rawDecimal == 0) ? null : rawDecimal;

    await into(inventoryLevelsTable).insertOnConflictUpdate(
      InventoryLevelsTableCompanion.insert(
        id: id,
        variantId: variantId,
        branchId: branchId,
        businessId: row['business_id'] as String,
        quantity: Value((row['quantity'] as int?) ?? 0),
        quantityDecimal: Value(decimal),
        lowStockAlertOverride: Value(row['low_stock_alert_override'] as int?),
        syncStatus: Value(SyncStatus.synced.toInt()),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Clear all levels (e.g. on logout).
  Future<void> clearAll() {
    return delete(inventoryLevelsTable).go();
  }
}
