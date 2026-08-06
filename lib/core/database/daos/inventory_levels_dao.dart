import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/inventory_levels_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'inventory_levels_dao.g.dart';

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
    return (select(
      inventoryLevelsTable,
    )..where((t) => t.businessId.equals(businessId))).get();
  }

  /// Watch all inventory level rows for a business (reactive).
  Stream<List<InventoryLevelsTableData>> watchByBusinessId(String businessId) {
    return (select(
      inventoryLevelsTable,
    )..where((t) => t.businessId.equals(businessId))).watch();
  }

  /// Inventory levels whose variant OR branch no longer exists locally.
  /// These can never sync (their parent is gone), so they're surfaced for
  /// admin review. This is read-only — it never deletes business data.
  Future<List<InventoryLevelsTableData>> findOrphans(String businessId) async {
    final levels = await (select(
      inventoryLevelsTable,
    )..where((t) => t.businessId.equals(businessId))).get();
    if (levels.isEmpty) return const [];

    final variantIds = (await customSelect(
      'SELECT id FROM product_variants',
    ).get()).map((r) => r.read<String>('id')).toSet();
    final branchIds = (await customSelect(
      'SELECT id FROM branches',
    ).get()).map((r) => r.read<String>('id')).toSet();

    return levels
        .where(
          (l) =>
              !variantIds.contains(l.variantId) ||
              !branchIds.contains(l.branchId),
        )
        .toList();
  }

  /// Get the level row for a specific variant + branch combo.
  Future<InventoryLevelsTableData?> getLevel(
    String variantId,
    String branchId,
  ) {
    final id = makeId(variantId, branchId);
    return (select(
      inventoryLevelsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Upsert a level row. Creates it if missing, replaces it if present.
  Future<void> upsertLevel({
    required String variantId,
    required String branchId,
    required String businessId,
    required double quantity,
  }) {
    final id = makeId(variantId, branchId);
    return into(inventoryLevelsTable).insertOnConflictUpdate(
      InventoryLevelsTableCompanion.insert(
        id: id,
        variantId: variantId,
        branchId: branchId,
        businessId: businessId,
        quantity: Value(quantity),
        syncStatus: const Value(1), // pendingUpdate
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Atomically adjust the quantity for a variant+branch by [delta].
  ///
  /// [delta] is a signed decimal — positive for stock-in, negative for
  /// stock-out — and holds whole units and fractions alike.
  ///
  /// A branch with no existing row starts from 0 — there is no global-stock
  /// seeding. Callers must NOT pass product_variants.stock as a seed.
  Future<void> adjustQuantity({
    required String variantId,
    required String branchId,
    required String businessId,
    required double delta,
    bool allowNegativeStock = false,
  }) async {
    final id = makeId(variantId, branchId);
    final existing = await (select(
      inventoryLevelsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    final current = existing?.quantity ?? 0.0;
    final rawNext = current + delta;
    final next = allowNegativeStock ? rawNext : rawNext.clamp(0.0, 999999.0);

    await into(inventoryLevelsTable).insertOnConflictUpdate(
      InventoryLevelsTableCompanion.insert(
        id: id,
        variantId: variantId,
        branchId: branchId,
        businessId: businessId,
        quantity: Value(next),
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
    return (select(
      inventoryLevelsTable,
    )..where((t) => t.variantId.equals(variantId))).get();
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = inventoryLevelsTable.id.count();
    final query = selectOnly(inventoryLevelsTable)
      ..addColumns([countExp])
      ..where(
        inventoryLevelsTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<InventoryLevelsTableData>> getPendingSync() {
    return (select(inventoryLevelsTable)..where(
          (t) => t.syncStatus.isIn([
            SyncStatus.pendingUpload.toInt(),
            SyncStatus.pendingUpdate.toInt(),
            SyncStatus.failed.toInt(),
          ]),
        ))
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
    final existing = await (select(
      inventoryLevelsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing != null && existing.syncStatus != SyncStatus.synced.toInt()) {
      return;
    }

    // Server `quantity` is the single source of truth. Fall back to a legacy
    // quantity_decimal only if an older server row still carries a non-zero one.
    final rawDecimal = (row['quantity_decimal'] as num?)?.toDouble();
    final qty = (rawDecimal != null && rawDecimal != 0)
        ? rawDecimal
        : ((row['quantity'] as num?)?.toDouble() ?? 0.0);

    await into(inventoryLevelsTable).insertOnConflictUpdate(
      InventoryLevelsTableCompanion.insert(
        id: id,
        variantId: variantId,
        branchId: branchId,
        businessId: row['business_id'] as String,
        quantity: Value(qty),
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
