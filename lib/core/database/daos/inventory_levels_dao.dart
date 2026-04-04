import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/inventory_levels_table.dart';

part 'inventory_levels_dao.g.dart';

@DriftAccessor(tables: [InventoryLevelsTable])
class InventoryLevelsDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryLevelsDaoMixin {
  InventoryLevelsDao(super.db);

  static String makeId(String variantId, String? branchId) =>
      '$variantId:${branchId ?? 'global'}';

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
    String? branchId,
  ) {
    final id = makeId(variantId, branchId);
    return (select(inventoryLevelsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Upsert a level row. Creates it if missing, replaces it if present.
  Future<void> upsertLevel({
    required String variantId,
    required String? branchId,
    required String businessId,
    required int quantity,
  }) {
    final id = makeId(variantId, branchId);
    return into(inventoryLevelsTable).insertOnConflictUpdate(
      InventoryLevelsTableCompanion.insert(
        id: id,
        variantId: variantId,
        branchId: Value(branchId),
        businessId: businessId,
        quantity: Value(quantity),
        syncStatus: const Value(1), // pendingUpdate
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Atomically adjust the quantity for a variant+branch by [delta].
  /// If no row exists yet, it is created starting from 0 + delta.
  Future<void> adjustQuantity({
    required String variantId,
    required String? branchId,
    required String businessId,
    required int delta,
  }) async {
    final id = makeId(variantId, branchId);
    final existing = await (select(inventoryLevelsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    final current = existing?.quantity ?? 0;
    final next = (current + delta).clamp(0, 999999);

    await into(inventoryLevelsTable).insertOnConflictUpdate(
      InventoryLevelsTableCompanion.insert(
        id: id,
        variantId: variantId,
        branchId: Value(branchId),
        businessId: businessId,
        quantity: Value(next),
        syncStatus: const Value(1),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get all level rows for a specific variant across all branches.
  Future<List<InventoryLevelsTableData>> getByVariantId(String variantId) {
    return (select(inventoryLevelsTable)
          ..where((t) => t.variantId.equals(variantId)))
        .get();
  }

  /// Clear all levels (e.g. on logout).
  Future<void> clearAll() {
    return delete(inventoryLevelsTable).go();
  }
}
