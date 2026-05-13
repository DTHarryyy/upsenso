import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/expenses_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [ExpensesTable])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Stream<List<ExpenseRow>> watchByBusinessId(String businessId) {
    return (select(expensesTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.syncStatus.isNotIn([SyncStatus.pendingDelete.toInt()]),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.expenseDate),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Future<List<ExpenseRow>> getByBusinessId(String businessId) {
    return (select(expensesTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.syncStatus.isNotIn([SyncStatus.pendingDelete.toInt()]),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.expenseDate)]))
        .get();
  }

  Future<void> insertExpense(ExpensesTableCompanion companion) {
    return into(expensesTable).insert(companion);
  }

  Future<void> updateExpense(String id, ExpensesTableCompanion companion) {
    return (update(
      expensesTable,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  /// Offline-first delete: marks the record as pendingDelete so the sync
  /// service will remove it from Supabase on the next run, then hard-deletes
  /// it locally. Rows that have never been uploaded are hard-deleted
  /// immediately since they never reached the server.
  Future<void> deleteExpense(String id) async {
    final row = await (select(
      expensesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    if (row.syncStatus == SyncStatus.pendingUpload.toInt()) {
      // Never uploaded — safe to hard-delete right away.
      await (delete(expensesTable)..where((t) => t.id.equals(id))).go();
    } else {
      // Already on server — mark for deletion; sync will clean up Supabase.
      await (update(expensesTable)..where((t) => t.id.equals(id))).write(
        ExpensesTableCompanion(
          syncStatus: Value(SyncStatus.pendingDelete.toInt()),
        ),
      );
    }
  }

  Future<void> clearAll() {
    return delete(expensesTable).go();
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = expensesTable.id.count();
    final query = selectOnly(expensesTable)
      ..addColumns([countExp])
      ..where(
        expensesTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.pendingDelete.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<ExpenseRow>> getPendingSync() {
    return (select(expensesTable)..where(
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
    return (update(expensesTable)..where((t) => t.id.equals(id))).write(
      ExpensesTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(expensesTable).insertOnConflictUpdate(
      ExpensesTableCompanion.insert(
        id: row['id'] as String,
        businessId: row['business_id'] as String,
        branchId: Value(row['branch_id'] as String?),
        branchName: Value(row['branch_name'] as String?),
        category: row['category'] as String,
        vendor: row['vendor'] as String,
        amount: (row['amount'] as num).toDouble(),
        status: Value(row['status'] as String? ?? 'pending'),
        submittedById: row['submitted_by_id'] as String,
        submittedByName: row['submitted_by_name'] as String,
        approvedById: Value(row['approved_by_id'] as String?),
        approvedByName: Value(row['approved_by_name'] as String?),
        note: Value(row['note'] as String?),
        expenseDate: DateTime.parse(row['expense_date'] as String),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(
          DateTime.parse(
            row['updated_at'] as String? ?? row['created_at'] as String,
          ),
        ),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(expensesTable)..where((t) => t.id.equals(id))).go();
  }
}
