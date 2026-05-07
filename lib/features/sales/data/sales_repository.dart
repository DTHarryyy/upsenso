import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';

/// Repository for the Sales History feature.
///
/// Wraps [TransactionsDao] so the presentation layer never touches the
/// database directly and the data source can be swapped in tests.
class SalesRepository {
  final TransactionsDao _txDao;

  const SalesRepository(this._txDao);

  /// Reactive stream of all transactions, optionally filtered to [branchId].
  /// Emits a new list whenever the underlying table changes.
  Stream<List<TransactionsTableData>> watchTransactions({String? branchId}) =>
      _txDao.watchTransactions(branchId: branchId);

  /// Fetches all line-items for a single transaction.
  Future<List<TransactionItemsTableData>> getTransactionItems(String txId) =>
      _txDao.getItemsByTransactionId(txId);
}
