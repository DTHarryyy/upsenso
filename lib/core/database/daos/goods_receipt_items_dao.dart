import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/goods_receipt_items_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'goods_receipt_items_dao.g.dart';

@DriftAccessor(tables: [GoodsReceiptItemsTable])
class GoodsReceiptItemsDao extends DatabaseAccessor<AppDatabase>
    with _$GoodsReceiptItemsDaoMixin {
  GoodsReceiptItemsDao(super.db);

  Future<void> insertAll(List<GoodsReceiptItemsTableCompanion> companions) {
    return batch((b) => b.insertAll(goodsReceiptItemsTable, companions));
  }

  Future<List<GoodsReceiptItemRow>> getByReceiptId(String receiptId) {
    return (select(goodsReceiptItemsTable)
          ..where((t) => t.goodsReceiptId.equals(receiptId)))
        .get();
  }

  Future<void> clearAll() => delete(goodsReceiptItemsTable).go();

  Stream<int> watchPendingSyncCount() {
    final countExp = goodsReceiptItemsTable.id.count();
    final query = selectOnly(goodsReceiptItemsTable)
      ..addColumns([countExp])
      ..where(
        goodsReceiptItemsTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.pendingDelete.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<GoodsReceiptItemRow>> getPendingSync() {
    return (select(goodsReceiptItemsTable)
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
    return (update(goodsReceiptItemsTable)..where((t) => t.id.equals(id)))
        .write(
          GoodsReceiptItemsTableCompanion(syncStatus: Value(status.toInt())),
        );
  }

  Future<void> hardDelete(String id) {
    return (delete(goodsReceiptItemsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(goodsReceiptItemsTable).insertOnConflictUpdate(
      GoodsReceiptItemsTableCompanion.insert(
        id: row['id'] as String,
        businessId: row['business_id'] as String,
        goodsReceiptId: row['goods_receipt_id'] as String,
        purchaseOrderLineId: row['purchase_order_line_id'] as String,
        variantId: row['variant_id'] as String,
        productId: row['product_id'] as String,
        productName: row['product_name'] as String,
        quantityReceived: Value(
          (row['quantity_received'] as num?)?.toDouble() ?? 0.0,
        ),
        unitCost: Value((row['unit_cost'] as num?)?.toDouble() ?? 0.0),
        createdAt: Value(
          row['created_at'] != null
              ? DateTime.parse(row['created_at'] as String)
              : DateTime.now(),
        ),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
  }
}
