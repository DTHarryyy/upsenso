import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/purchase_order_lines_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'purchase_order_lines_dao.g.dart';

@DriftAccessor(tables: [PurchaseOrderLinesTable])
class PurchaseOrderLinesDao extends DatabaseAccessor<AppDatabase>
    with _$PurchaseOrderLinesDaoMixin {
  PurchaseOrderLinesDao(super.db);

  Stream<List<PurchaseOrderLineRow>> watchByPoId(String poId) {
    return (select(purchaseOrderLinesTable)
          ..where(
            (t) =>
                t.purchaseOrderId.equals(poId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<List<PurchaseOrderLineRow>> getByPoId(String poId) {
    return (select(purchaseOrderLinesTable)
          ..where(
            (t) =>
                t.purchaseOrderId.equals(poId) & t.isDeleted.equals(false),
          ))
        .get();
  }

  Future<PurchaseOrderLineRow?> getById(String id) {
    return (select(purchaseOrderLinesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insert(PurchaseOrderLinesTableCompanion companion) {
    return into(purchaseOrderLinesTable).insert(companion);
  }

  Future<void> insertAll(List<PurchaseOrderLinesTableCompanion> companions) {
    return batch((b) => b.insertAll(purchaseOrderLinesTable, companions));
  }

  Future<void> updateLine(
    String id,
    PurchaseOrderLinesTableCompanion companion,
  ) {
    return (update(purchaseOrderLinesTable)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> softDeleteByPoId(String poId) async {
    await (update(purchaseOrderLinesTable)
          ..where((t) => t.purchaseOrderId.equals(poId)))
        .write(
          PurchaseOrderLinesTableCompanion(
            isDeleted: const Value(true),
            syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
            localUpdatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> clearAll() => delete(purchaseOrderLinesTable).go();

  Stream<int> watchPendingSyncCount() {
    final countExp = purchaseOrderLinesTable.id.count();
    final query = selectOnly(purchaseOrderLinesTable)
      ..addColumns([countExp])
      ..where(
        purchaseOrderLinesTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.pendingDelete.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<PurchaseOrderLineRow>> getPendingSync() {
    return (select(purchaseOrderLinesTable)
          ..where(
            (t) => t.syncStatus.isIn([
              SyncStatus.pendingUpload.toInt(),
              SyncStatus.pendingUpdate.toInt(),
              SyncStatus.pendingDelete.toInt(),
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
    return (update(purchaseOrderLinesTable)
          ..where((t) => t.id.equals(id)))
        .write(
          PurchaseOrderLinesTableCompanion(
            syncStatus: Value(status.toInt()),
          ),
        );
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(purchaseOrderLinesTable).insertOnConflictUpdate(
      PurchaseOrderLinesTableCompanion.insert(
        id: row['id'] as String,
        purchaseOrderId: row['purchase_order_id'] as String,
        businessId: row['business_id'] as String,
        productId: row['product_id'] as String,
        variantId: row['variant_id'] as String,
        productName: row['product_name'] as String,
        variantName: row['variant_name'] as String,
        sku: Value(row['sku'] as String?),
        quantityOrdered: Value(
          (row['quantity_ordered'] as num?)?.toDouble() ?? 0.0,
        ),
        quantityReceived: Value(
          (row['quantity_received'] as num?)?.toDouble() ?? 0.0,
        ),
        unitCost: Value((row['unit_cost'] as num?)?.toDouble() ?? 0.0),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        createdAt: Value(
          row['created_at'] != null
              ? DateTime.parse(row['created_at'] as String)
              : DateTime.now(),
        ),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(purchaseOrderLinesTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> hardDeleteByPoId(String poId) {
    return (delete(purchaseOrderLinesTable)
          ..where((t) => t.purchaseOrderId.equals(poId)))
        .go();
  }
}
