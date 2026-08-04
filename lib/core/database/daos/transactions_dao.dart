import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/transactions_table.dart';
import 'package:pos/core/database/tables/transaction_items_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable, TransactionItemsTable])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// Updates the invoice_number for a transaction that was saved offline with
  /// a locally-generated number that later collided on Supabase sync.
  Future<void> updateInvoiceNumber(String txId, String invoiceNumber) {
    return (update(transactionsTable)..where((t) => t.id.equals(txId))).write(
      TransactionsTableCompanion(invoiceNumber: Value(invoiceNumber)),
    );
  }

  /// Atomically inserts a transaction and all its line-items in one transaction.
  Future<void> insertTransaction(
    TransactionsTableCompanion tx,
    List<TransactionItemsTableCompanion> items,
  ) async {
    await transaction(() async {
      await into(transactionsTable).insert(tx);
      if (items.isNotEmpty) {
        await batch((b) {
          for (final item in items) {
            b.insert(transactionItemsTable, item);
          }
        });
      }
    });
  }

  /// Fetch all line-items for a given transaction.
  Future<List<TransactionItemsTableData>> getItemsByTransactionId(
    String transactionId,
  ) {
    return (select(
      transactionItemsTable,
    )..where((t) => t.transactionId.equals(transactionId))).get();
  }

  /// Records pending upload/retry, plus pendingUpdate(1) — the latter is
  /// status-only changes written by a refund (transactions are otherwise
  /// immutable once created).
  Future<List<TransactionsTableData>> getPendingSync() {
    return (select(
      transactionsTable,
    )..where((t) => t.syncStatus.isIn([0, 1, 4]))).get();
  }

  /// Recomputes and writes `status` after a refund. Queues a status-only
  /// push (`pendingUpdate`) rather than re-uploading the whole row — the
  /// sale itself never changes, only this derived flag.
  /// Does nothing to a row that is still `pendingUpload` (0): an unsynced
  /// local row's full create payload already carries the new status, so a
  /// separate status-only push would race the initial upload.
  Future<void> updateStatus(String id, String status) async {
    final existing = await getById(id);
    if (existing == null) return;
    final nextSyncStatus = existing.syncStatus == SyncStatus.pendingUpload.toInt()
        ? existing.syncStatus
        : SyncStatus.pendingUpdate.toInt();
    await (update(transactionsTable)..where((t) => t.id.equals(id))).write(
      TransactionsTableCompanion(
        status: Value(status),
        syncStatus: Value(nextSyncStatus),
      ),
    );
  }

  /// Reconciles `status` from pulled refund rows during sync — a self-heal
  /// path, not a new local change, so it never touches `syncStatus`. Pushing
  /// the same status right back would just create pointless push/pull churn
  /// between devices.
  Future<void> updateStatusFromServer(String id, String status) {
    return (update(transactionsTable)..where((t) => t.id.equals(id))).write(
      TransactionsTableCompanion(status: Value(status)),
    );
  }

  /// Update sync status after a sync attempt.
  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) async {
    await (update(transactionsTable)..where((t) => t.id.equals(id))).write(
      TransactionsTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// Upsert a transaction_item row pulled from Supabase.
  Future<void> upsertItemFromServer(Map<String, dynamic> row) {
    return into(transactionItemsTable).insertOnConflictUpdate(
      TransactionItemsTableCompanion.insert(
        id: row['id'] as String,
        transactionId: row['transaction_id'] as String,
        variantId: row['variant_id'] as String,
        productName: row['product_name'] as String,
        variantName: row['variant_name'] as String,
        unitPrice: (row['unit_price'] as num).toDouble(),
        taxRate: Value((row['tax_rate'] as num?)?.toDouble()),
        qty: (row['qty'] as num).toDouble(),
        lineTotal: (row['line_total'] as num).toDouble(),
        lineTax: (row['line_tax'] as num).toDouble(),
      ),
    );
  }

  /// Upsert a transaction row pulled from Supabase (marks as synced).
  /// payment_method, customer_id and discount_amount are synced via Supabase.
  /// Local-only fields with no server column (customerName, itemCount) are
  /// preserved as-is for an existing row, and best-effort recomputed by the
  /// caller for a new one — see [recomputeItemCounts] and
  /// [backfillCustomerNames], run by the pull after this upsert.
  ///
  /// Note: createdAt is intentionally NOT overwritten when the row exists
  /// locally, to preserve the original local timestamp (Supabase may store
  /// it in UTC which would cause incorrect display times after tz conversion).
  Future<void> upsertFromServer(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final paymentMethod = (row['payment_method'] as String?) ?? 'cash';
    // Carry the server status so reports can filter status=='completed' and
    // exclude voided/refunded sales pulled from other devices.
    final status = (row['status'] as String?) ?? 'completed';
    final customerId = row['customer_id'] as String?;
    final discountAmount = (row['discount_amount'] as num?)?.toDouble() ?? 0;
    final existing = await (select(
      transactionsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing != null) {
      // Never clobber a local sale that hasn't reached the server yet. Flipping
      // it to "synced" here would stop _syncTransactions from ever pushing it —
      // a silently lost sale. Leave unsynced rows for the push pass to handle.
      if (existing.syncStatus != SyncStatus.synced.toInt()) {
        return;
      }
      // Row exists locally — preserve original createdAt; only update
      // server-controlled fields (totals, payment, invoice_number, sync metadata).
      await (update(transactionsTable)..where((t) => t.id.equals(id))).write(
        TransactionsTableCompanion(
          cashierId: Value(row['cashier_id'] as String),
          branchId: Value(row['branch_id'] as String?),
          shiftId: Value(row['shift_id'] as String?),
          totalAmount: Value((row['total_amount'] as num).toDouble()),
          discountAmount: Value(discountAmount),
          taxAmount: Value((row['tax_amount'] as num).toDouble()),
          status: Value(status),
          paymentMethod: Value(paymentMethod),
          invoiceNumber: Value(row['invoice_number'] as String?),
          customerId: Value(customerId),
          syncStatus: const Value(3),
          lastSyncAttempt: Value(DateTime.now()),
        ),
      );
    } else {
      // New row from server — insert with payment_method from server.
      // For new server rows, use server's created_at timestamp.
      final createdAt = DateTime.parse(row['created_at'] as String);
      final totalAmount = (row['total_amount'] as num).toDouble();
      final taxAmount = (row['tax_amount'] as num).toDouble();
      await into(transactionsTable).insert(
        TransactionsTableCompanion.insert(
          id: id,
          cashierId: row['cashier_id'] as String,
          // Carry tenant + invoice from the server row. Omitting business_id
          // here is what left synced sales with a null tenant and made them
          // invisible to the business-scoped report queries below.
          businessId: Value(row['business_id'] as String?),
          branchId: Value(row['branch_id'] as String?),
          shiftId: Value(row['shift_id'] as String?),
          totalAmount: totalAmount,
          discountAmount: Value(discountAmount),
          taxAmount: taxAmount,
          // subtotal has no server column; total = subtotal - discount + tax
          // (see CartTotals.compute), so it's exactly reconstructible.
          subtotal: totalAmount + discountAmount - taxAmount,
          // itemCount has no server column either — 0 until
          // recomputeItemCounts fills it in from the pulled line items.
          itemCount: 0,
          status: Value(status),
          paymentMethod: Value(paymentMethod),
          invoiceNumber: Value(row['invoice_number'] as String?),
          customerId: Value(customerId),
          syncStatus: const Value(3),
          lastSyncAttempt: Value(DateTime.now()),
          createdAt: Value(createdAt),
        ),
      );
    }
  }

  /// One-time repair for rows pulled before the upsert fix above, which were
  /// stored with a null business_id and so vanished from the business-scoped
  /// report queries. Pull is always per-business, so every synced row on this
  /// device belongs to the active business — pass it in explicitly (never read
  /// session here; the DAO must stay tenant-agnostic). Returns rows repaired.
  Future<int> backfillNullBusinessId(String businessId) {
    return (update(transactionsTable)
          ..where(
            (t) =>
                t.businessId.isNull() &
                t.syncStatus.equals(SyncStatus.synced.toInt()),
          ))
        .write(TransactionsTableCompanion(businessId: Value(businessId)));
  }

  /// Recomputes itemCount for rows pulled from the server — item_count has no
  /// server column, so [upsertFromServer] inserts new rows with a placeholder
  /// 0. Counts the same way checkout does (see product_checkout_page.dart):
  /// a whole-quantity line counts by its qty; a weighed/fractional line
  /// counts as a single item. Only rewrites rows still at the placeholder —
  /// a row with a real count already has it and must not be touched.
  Future<void> recomputeItemCounts(List<String> transactionIds) async {
    if (transactionIds.isEmpty) return;
    final items = await getItemsForTransactions(transactionIds);
    final counts = <String, int>{};
    for (final item in items) {
      final contribution =
          item.qty == item.qty.roundToDouble() ? item.qty.round() : 1;
      counts.update(
        item.transactionId,
        (n) => n + contribution,
        ifAbsent: () => contribution,
      );
    }
    await transaction(() async {
      for (final entry in counts.entries) {
        await (update(transactionsTable)..where(
              (t) => t.id.equals(entry.key) & t.itemCount.equals(0),
            ))
            .write(TransactionsTableCompanion(itemCount: Value(entry.value)));
      }
    });
  }

  /// Fills the local-only customer_name snapshot for rows pulled from the
  /// server with a customer_id but no name yet, by joining the locally-synced
  /// customers table. Run after the customers pull so names are available.
  /// Only fills a blank snapshot — an existing one is frozen on purpose (the
  /// customer may have been renamed/archived since the sale).
  Future<void> backfillCustomerNames(String businessId) {
    return customStatement(
      'UPDATE transactions '
      'SET customer_name = ('
      '  SELECT name FROM customers WHERE customers.id = transactions.customer_id'
      ') '
      'WHERE transactions.business_id = ? '
      'AND transactions.customer_id IS NOT NULL '
      "AND (transactions.customer_name IS NULL OR transactions.customer_name = '') "
      'AND EXISTS ('
      '  SELECT 1 FROM customers WHERE customers.id = transactions.customer_id'
      ')',
      [businessId],
    );
  }

  /// One-time re-queue so sales that already reached the server before
  /// customer_id was part of the push payload get re-uploaded with it. Marks
  /// every synced row that has a local customerId back to pendingUpload;
  /// idempotent (a row already pendingUpload is left alone) but the caller
  /// (SyncService) should still gate this to run once per business via
  /// SyncStateDao — otherwise it re-fires every sync cycle.
  Future<int> queueCustomerIdBackfill() {
    return (update(transactionsTable)
          ..where(
            (t) =>
                t.customerId.isNotNull() &
                t.syncStatus.equals(SyncStatus.synced.toInt()),
          ))
        .write(
          TransactionsTableCompanion(
            syncStatus: Value(SyncStatus.pendingUpload.toInt()),
          ),
        );
  }

  /// Reactive count of transactions that need syncing (for status bar).
  Stream<int> watchPendingSyncCount() {
    final countExp = transactionsTable.id.count();
    final query = selectOnly(transactionsTable)
      ..addColumns([countExp])
      ..where(transactionsTable.syncStatus.isIn([0, 4]));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  /// Watch all completed transactions ordered by date, optionally filtered by branch.
  Stream<List<TransactionsTableData>> watchTransactions({String? branchId}) {
    final query = select(transactionsTable)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    if (branchId != null) {
      query.where((t) => t.branchId.equals(branchId));
    }
    return query.watch();
  }

  /// Watch a customer's completed sales (purchase history), newest first.
  /// Business-scoped so a customer id never leaks another tenant's rows.
  Stream<List<TransactionsTableData>> watchByCustomerId({
    required String businessId,
    required String customerId,
  }) {
    return (select(transactionsTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.customerId.equals(customerId) &
                t.status.equals('completed'),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Fetch a single transaction by ID.
  Future<TransactionsTableData?> getById(String id) {
    return (select(
      transactionsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Clear all transactions and items (e.g., on logout/reset).
  Future<void> clearAll() async {
    await delete(transactionItemsTable).go();
    await delete(transactionsTable).go();
  }

  /// Fetch all transactions since [cutoff], filtered by business.
  /// Optionally further filtered by [branchId].
  Future<List<TransactionsTableData>> getTransactionsSince(
    DateTime cutoff, {
    required String businessId,
    String? branchId,
  }) {
    final query = select(transactionsTable)
      ..where((t) {
        // Only this business's rows. Null-business rows are excluded — they
        // would otherwise leak another tenant's sales into reports.
        Expression<bool> cond = t.createdAt.isBiggerOrEqualValue(cutoff) &
            t.businessId.equals(businessId);
        if (branchId != null) {
          cond = cond & t.branchId.equals(branchId);
        }
        return cond;
      })
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.get();
  }

  /// Fetch ALL transactions (all branches) for this business since [cutoff].
  /// Used for branch comparison charts.
  Future<List<TransactionsTableData>> getAllTransactionsSince(
    DateTime cutoff, {
    required String businessId,
  }) {
    return (select(transactionsTable)
          ..where(
            // Exclude null-business rows so one tenant's sales never leak into
            // another business's branch-comparison charts.
            (t) =>
                t.createdAt.isBiggerOrEqualValue(cutoff) &
                t.businessId.equals(businessId),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Fetch all line-items whose transaction is in [transactionIds].
  Future<List<TransactionItemsTableData>> getItemsForTransactions(
    List<String> transactionIds,
  ) {
    if (transactionIds.isEmpty) return Future.value([]);
    return (select(
      transactionItemsTable,
    )..where((t) => t.transactionId.isIn(transactionIds))).get();
  }

  /// Returns a map of transactionId → actual line-item count from
  /// transaction_items. Used to show the real count even when the
  /// stored itemCount column is stale (e.g. rows synced from Supabase).
  Future<Map<String, int>> getItemCountsForTransactions(
    List<String> transactionIds,
  ) async {
    if (transactionIds.isEmpty) return {};
    final rows = await (select(
      transactionItemsTable,
    )..where((t) => t.transactionId.isIn(transactionIds))).get();
    final counts = <String, int>{};
    for (final row in rows) {
      counts[row.transactionId] = (counts[row.transactionId] ?? 0) + 1;
    }
    return counts;
  }
}
