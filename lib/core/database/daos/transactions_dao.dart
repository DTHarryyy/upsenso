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
    return (select(transactionItemsTable)
          ..where((t) => t.transactionId.equals(transactionId)))
        .get();
  }

  /// Records pending upload or retry (transactions are immutable).
  Future<List<TransactionsTableData>> getPendingSync() {
    return (select(transactionsTable)
          ..where((t) => t.syncStatus.isIn([0, 4])))
        .get();
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

  /// Upsert a transaction row pulled from Supabase (marks as synced).
  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(transactionsTable).insertOnConflictUpdate(
      TransactionsTableCompanion.insert(
        id: row['id'] as String,
        cashierId: row['cashier_id'] as String,
        branchId: Value(row['branch_id'] as String?),
        shiftId: Value(row['shift_id'] as String?),
        totalAmount: (row['total_amount'] as num).toDouble(),
        taxAmount: (row['tax_amount'] as num).toDouble(),
        subtotal: (row['total_amount'] as num).toDouble(), // best estimate
        itemCount: 0,
        syncStatus: const Value(3), // synced
        lastSyncAttempt: Value(DateTime.now()),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
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
  Stream<List<TransactionsTableData>> watchTransactions({
    String? branchId,
  }) {
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
    return (select(transactionsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Clear all transactions and items (e.g., on logout/reset).
  Future<void> clearAll() async {
    await delete(transactionItemsTable).go();
    await delete(transactionsTable).go();
  }
}
