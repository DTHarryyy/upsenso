import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/refunds_table.dart';
import 'package:pos/core/database/tables/refund_items_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'refunds_dao.g.dart';

/// Refunds are append-only header+lines, always read/written together —
/// same shape as [TransactionsDao] for transactions/transaction_items, so
/// this mirrors that DAO's structure (one accessor for the parent+child pair).
@DriftAccessor(tables: [RefundsTable, RefundItemsTable])
class RefundsDao extends DatabaseAccessor<AppDatabase>
    with _$RefundsDaoMixin {
  RefundsDao(super.db);

  /// Atomically inserts a refund header and its lines in one transaction.
  Future<void> insertRefund(
    RefundsTableCompanion refund,
    List<RefundItemsTableCompanion> items,
  ) async {
    await transaction(() async {
      await into(refundsTable).insert(refund);
      if (items.isNotEmpty) {
        await batch((b) {
          for (final item in items) {
            b.insert(refundItemsTable, item);
          }
        });
      }
    });
  }

  /// Fetch all refund headers for a transaction (most recent first).
  Future<List<RefundsTableData>> getByTransactionId(String transactionId) {
    return (select(refundsTable)
          ..where((t) => t.transactionId.equals(transactionId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Fetch all lines for a single refund event.
  Future<List<RefundItemsTableData>> getItemsByRefundId(String refundId) {
    return (select(
      refundItemsTable,
    )..where((t) => t.refundId.equals(refundId))).get();
  }

  /// Fetch all lines whose refund is in [refundIds]. Mirrors
  /// [TransactionsDao.getItemsForTransactions] — used by reports to reverse
  /// COGS for refunded items.
  Future<List<RefundItemsTableData>> getItemsForRefunds(
    List<String> refundIds,
  ) {
    if (refundIds.isEmpty) return Future.value([]);
    return (select(
      refundItemsTable,
    )..where((t) => t.refundId.isIn(refundIds))).get();
  }

  /// Sum of refunded qty per `transaction_item_id`, across every refund event
  /// for [transactionId]. Used to recompute the parent transaction's status
  /// and to enforce the over-refund guard (sold qty − already-refunded qty).
  Future<Map<String, double>> getRefundedQtyByTransactionId(
    String transactionId,
  ) async {
    final qtyExp = refundItemsTable.qty.sum();
    final query =
        select(refundItemsTable).join([
            innerJoin(
              refundsTable,
              refundsTable.id.equalsExp(refundItemsTable.refundId),
            ),
          ])
          ..where(refundsTable.transactionId.equals(transactionId))
          ..groupBy([refundItemsTable.transactionItemId]);
    query.addColumns([qtyExp]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.readTable(refundItemsTable).transactionItemId:
            row.read(qtyExp) ?? 0.0,
    };
  }

  /// Same aggregation as [getRefundedQtyByTransactionId] but scoped to a
  /// specific set of `transaction_item_id`s instead of one transaction —
  /// used by Sales History to batch-load refunded-so-far qty for whichever
  /// lines are currently expanded on screen.
  Future<Map<String, double>> getRefundedQtyForTransactionItems(
    List<String> transactionItemIds,
  ) async {
    if (transactionItemIds.isEmpty) return {};
    final qtyExp = refundItemsTable.qty.sum();
    final query = selectOnly(refundItemsTable)
      ..addColumns([refundItemsTable.transactionItemId, qtyExp])
      ..where(refundItemsTable.transactionItemId.isIn(transactionItemIds))
      ..groupBy([refundItemsTable.transactionItemId]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(refundItemsTable.transactionItemId)!: row.read(qtyExp) ?? 0.0,
    };
  }

  /// Sum of `total_amount` per `transaction_id`, batched across many
  /// transactions at once — used by Sales History to show each sale's net
  /// amount and status without a query per row.
  Future<Map<String, double>> getRefundedAmountForTransactions(
    List<String> transactionIds,
  ) async {
    if (transactionIds.isEmpty) return {};
    final amountExp = refundsTable.totalAmount.sum();
    final query = selectOnly(refundsTable)
      ..addColumns([refundsTable.transactionId, amountExp])
      ..where(refundsTable.transactionId.isIn(transactionIds))
      ..groupBy([refundsTable.transactionId]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(refundsTable.transactionId)!: row.read(amountExp) ?? 0.0,
    };
  }

  /// Refund headers since [cutoff] for revenue subtraction in reports.
  /// Mirrors [TransactionsDao.getTransactionsSince].
  Future<List<RefundsTableData>> getRefundsSince(
    DateTime cutoff, {
    required String businessId,
    String? branchId,
  }) {
    final query = select(refundsTable)
      ..where((t) {
        Expression<bool> cond =
            t.createdAt.isBiggerOrEqualValue(cutoff) &
            t.businessId.equals(businessId);
        if (branchId != null) {
          cond = cond & t.branchId.equals(branchId);
        }
        return cond;
      })
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.get();
  }

  /// Refund headers since [cutoff] across ALL branches of [businessId].
  /// Mirrors [TransactionsDao.getAllTransactionsSince] (branch comparison).
  Future<List<RefundsTableData>> getAllRefundsSince(
    DateTime cutoff, {
    required String businessId,
  }) {
    return (select(refundsTable)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(cutoff) &
                t.businessId.equals(businessId),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Records pending upload or retry (refunds are append-only, never edited).
  Future<List<RefundsTableData>> getPendingSync() {
    return (select(
      refundsTable,
    )..where((t) => t.syncStatus.isIn([0, 4]))).get();
  }

  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) {
    return (update(refundsTable)..where((t) => t.id.equals(id))).write(
      RefundsTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// Upsert a refund header pulled from Supabase (marks as synced).
  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(refundsTable).insertOnConflictUpdate(
      RefundsTableCompanion.insert(
        id: row['id'] as String,
        transactionId: row['transaction_id'] as String,
        businessId: row['business_id'] as String,
        branchId: Value(row['branch_id'] as String?),
        refundedBy: row['refunded_by'] as String,
        totalAmount: (row['total_amount'] as num).toDouble(),
        taxAmount: Value((row['tax_amount'] as num?)?.toDouble() ?? 0.0),
        reason: Value(row['reason'] as String?),
        createdAt: Value(
          row['created_at'] != null
              ? DateTime.parse(row['created_at'] as String)
              : DateTime.now(),
        ),
        updatedAt: Value(
          row['updated_at'] != null
              ? DateTime.parse(row['updated_at'] as String)
              : DateTime.now(),
        ),
        clientUpdatedAt: Value(
          row['client_updated_at'] != null
              ? DateTime.parse(row['client_updated_at'] as String)
              : DateTime.now(),
        ),
        deletedAt: Value(
          row['deleted_at'] != null
              ? DateTime.parse(row['deleted_at'] as String)
              : null,
        ),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
  }

  /// Upsert a refund line pulled from Supabase.
  Future<void> upsertItemFromServer(Map<String, dynamic> row) {
    return into(refundItemsTable).insertOnConflictUpdate(
      RefundItemsTableCompanion.insert(
        id: row['id'] as String,
        refundId: row['refund_id'] as String,
        transactionItemId: row['transaction_item_id'] as String,
        variantId: row['variant_id'] as String,
        qty: (row['qty'] as num).toDouble(),
        amount: (row['amount'] as num).toDouble(),
        restocked: Value((row['restocked'] as bool?) ?? true),
      ),
    );
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = refundsTable.id.count();
    final query = selectOnly(refundsTable)
      ..addColumns([countExp])
      ..where(refundsTable.syncStatus.isIn([0, 4]));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  /// Clear all refunds and lines (e.g., on logout/reset).
  Future<void> clearAll() async {
    await delete(refundItemsTable).go();
    await delete(refundsTable).go();
  }
}
