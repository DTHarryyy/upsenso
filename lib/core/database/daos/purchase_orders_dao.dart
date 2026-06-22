import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/purchase_order_lines_table.dart';
import 'package:pos/core/database/tables/purchase_orders_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'purchase_orders_dao.g.dart';

/// A PO row paired with its aggregated received/ordered quantities, so the list
/// can show the same receiving progress as the detail page without loading
/// every line.
typedef PoWithProgress = ({
  PurchaseOrderRow po,
  double ordered,
  double received,
});

@DriftAccessor(tables: [PurchaseOrdersTable, PurchaseOrderLinesTable])
class PurchaseOrdersDao extends DatabaseAccessor<AppDatabase>
    with _$PurchaseOrdersDaoMixin {
  PurchaseOrdersDao(super.db);

  Stream<List<PurchaseOrderRow>> watchByBusinessId(String businessId) {
    return (select(purchaseOrdersTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Like [watchByBusinessId] but left-joins line totals so each PO carries its
  /// ordered/received sums (non-deleted lines only) in one reactive query.
  Stream<List<PoWithProgress>> watchByBusinessIdWithProgress(
    String businessId,
  ) {
    final orderedExp = purchaseOrderLinesTable.quantityOrdered.sum();
    final receivedExp = purchaseOrderLinesTable.quantityReceived.sum();

    final query =
        select(purchaseOrdersTable).join([
          leftOuterJoin(
            purchaseOrderLinesTable,
            purchaseOrderLinesTable.purchaseOrderId.equalsExp(
                  purchaseOrdersTable.id,
                ) &
                purchaseOrderLinesTable.isDeleted.equals(false),
          ),
        ])
          ..where(
            purchaseOrdersTable.businessId.equals(businessId) &
                purchaseOrdersTable.isDeleted.equals(false),
          )
          ..groupBy([purchaseOrdersTable.id])
          ..orderBy([OrderingTerm.desc(purchaseOrdersTable.createdAt)]);
    query.addColumns([orderedExp, receivedExp]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (
              po: row.readTable(purchaseOrdersTable),
              ordered: row.read(orderedExp) ?? 0.0,
              received: row.read(receivedExp) ?? 0.0,
            ),
          )
          .toList(),
    );
  }

  Future<List<PurchaseOrderRow>> getByBusinessId(String businessId) {
    return (select(purchaseOrdersTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<PurchaseOrderRow?> getById(String id) {
    return (select(purchaseOrdersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insert(PurchaseOrdersTableCompanion companion) {
    return into(purchaseOrdersTable).insert(companion);
  }

  Future<void> updatePo(String id, PurchaseOrdersTableCompanion companion) {
    return (update(purchaseOrdersTable)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> softDelete(String id) async {
    await (update(purchaseOrdersTable)..where((t) => t.id.equals(id))).write(
      PurchaseOrdersTableCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
        syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearAll() => delete(purchaseOrdersTable).go();

  Stream<int> watchPendingSyncCount() {
    final countExp = purchaseOrdersTable.id.count();
    final query = selectOnly(purchaseOrdersTable)
      ..addColumns([countExp])
      ..where(
        purchaseOrdersTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.pendingDelete.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<PurchaseOrderRow>> getPendingSync() {
    return (select(purchaseOrdersTable)
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
    return (update(purchaseOrdersTable)..where((t) => t.id.equals(id))).write(
      PurchaseOrdersTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(purchaseOrdersTable).insertOnConflictUpdate(
      PurchaseOrdersTableCompanion.insert(
        id: row['id'] as String,
        businessId: row['business_id'] as String,
        branchId: Value(row['branch_id'] as String?),
        supplierId: Value(row['supplier_id'] as String?),
        supplierName: Value(row['supplier_name'] as String?),
        status: Value(
          (row['status'] as String?) ?? 'draft',
        ),
        poNumber: row['po_number'] as String,
        notes: Value(row['notes'] as String?),
        expectedDelivery: Value(
          row['expected_delivery'] != null
              ? DateTime.parse(row['expected_delivery'] as String)
              : null,
        ),
        discount: Value((row['discount'] as num?)?.toDouble() ?? 0.0),
        shipping: Value((row['shipping'] as num?)?.toDouble() ?? 0.0),
        totalAmount: Value((row['total_amount'] as num?)?.toDouble() ?? 0.0),
        createdById: Value(row['created_by_id'] as String?),
        createdByName: Value(row['created_by_name'] as String?),
        submittedAt: Value(
          row['submitted_at'] != null
              ? DateTime.parse(row['submitted_at'] as String)
              : null,
        ),
        approvedAt: Value(
          row['approved_at'] != null
              ? DateTime.parse(row['approved_at'] as String)
              : null,
        ),
        approvedById: Value(row['approved_by_id'] as String?),
        approvedByName: Value(row['approved_by_name'] as String?),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        deletedAt: Value(
          row['deleted_at'] != null
              ? DateTime.parse(row['deleted_at'] as String)
              : null,
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

  Future<void> hardDelete(String id) {
    return (delete(purchaseOrdersTable)..where((t) => t.id.equals(id))).go();
  }
}
