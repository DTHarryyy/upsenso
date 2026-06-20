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
  /// payment_method is now synced via Supabase; other local-only fields
  /// (itemCount, customerName, subtotal, amountReceived, changeDue) are
  /// preserved if the row already exists.
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
          taxAmount: Value((row['tax_amount'] as num).toDouble()),
          status: Value(status),
          paymentMethod: Value(paymentMethod),
          invoiceNumber: Value(row['invoice_number'] as String?),
          syncStatus: const Value(3),
          lastSyncAttempt: Value(DateTime.now()),
        ),
      );
    } else {
      // New row from server — insert with payment_method from server.
      // For new server rows, use server's created_at timestamp.
      final createdAt = DateTime.parse(row['created_at'] as String);
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
          totalAmount: (row['total_amount'] as num).toDouble(),
          taxAmount: (row['tax_amount'] as num).toDouble(),
          subtotal: (row['total_amount'] as num).toDouble(),
          itemCount: 0,
          status: Value(status),
          paymentMethod: Value(paymentMethod),
          invoiceNumber: Value(row['invoice_number'] as String?),
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
