import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/goods_receipts_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'goods_receipts_dao.g.dart';

@DriftAccessor(tables: [GoodsReceiptsTable])
class GoodsReceiptsDao extends DatabaseAccessor<AppDatabase>
    with _$GoodsReceiptsDaoMixin {
  GoodsReceiptsDao(super.db);

  Stream<List<GoodsReceiptRow>> watchByPoId(String poId) {
    return (select(goodsReceiptsTable)
          ..where(
            (t) => t.purchaseOrderId.equals(poId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
        .watch();
  }

  Future<void> insert(GoodsReceiptsTableCompanion companion) {
    return into(goodsReceiptsTable).insert(companion);
  }

  Future<void> clearAll() => delete(goodsReceiptsTable).go();

  Stream<int> watchPendingSyncCount() {
    final countExp = goodsReceiptsTable.id.count();
    final query = selectOnly(goodsReceiptsTable)
      ..addColumns([countExp])
      ..where(
        goodsReceiptsTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.pendingDelete.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<GoodsReceiptRow>> getPendingSync() {
    return (select(goodsReceiptsTable)
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
    return (update(goodsReceiptsTable)..where((t) => t.id.equals(id))).write(
      GoodsReceiptsTableCompanion(syncStatus: Value(status.toInt())),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(goodsReceiptsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final existing = await (select(goodsReceiptsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (existing != null && existing.syncStatus != SyncStatus.synced.toInt()) {
      return;
    }
    await into(goodsReceiptsTable).insertOnConflictUpdate(
      GoodsReceiptsTableCompanion.insert(
        id: id,
        businessId: row['business_id'] as String,
        purchaseOrderId: row['purchase_order_id'] as String,
        branchId: row['branch_id'] as String,
        receiptNumber: row['receipt_number'] as String,
        receivedById: Value(row['received_by_id'] as String?),
        receivedByName: Value(row['received_by_name'] as String?),
        notes: Value(row['notes'] as String?),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        receivedAt: Value(
          row['received_at'] != null
              ? DateTime.parse(row['received_at'] as String)
              : DateTime.now(),
        ),
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
