import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/features/sales/domain/entities/sale_item.dart';
import 'package:pos/features/sales/domain/entities/sale_transaction.dart';
import 'package:pos/features/sales/domain/repositories/i_sales_repository.dart';

/// Data-layer implementation of [ISalesRepository].
///
/// Wraps [TransactionsDao] and maps Drift-generated table rows to pure domain
/// entities, ensuring the presentation layer is fully decoupled from the DB.
class SalesRepository implements ISalesRepository {
  final TransactionsDao _txDao;
  final EmployeesDao _employeesDao;

  const SalesRepository(this._txDao, this._employeesDao);

  @override
  Stream<List<SaleTransaction>> watchTransactions({
    String? branchId,
  }) => _txDao.watchTransactions(branchId: branchId).asyncMap((rows) async {
    final ids = rows.map((r) => r.id).toList();
    final counts = await _txDao.getItemCountsForTransactions(ids);
    // Batch-resolve cashier names from the employees table.
    final cashierIds = rows
        .map((r) => r.cashierId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final cashierNames = await _employeesDao.getNamesForAuthUserIds(cashierIds);
    return rows.map((r) {
      // Use actual count from transaction_items; fall back to stored
      // itemCount only if no items exist yet (brand-new transaction
      // not yet committed to the items table).
      final realCount = counts.containsKey(r.id) ? counts[r.id]! : r.itemCount;
      return _mapTransaction(
        r,
        itemCount: realCount,
        cashierName: cashierNames[r.cashierId],
      );
    }).toList();
  });

  @override
  Future<List<SaleItem>> getTransactionItems(String transactionId) async {
    final rows = await _txDao.getItemsByTransactionId(transactionId);
    return rows.map(_mapItem).toList();
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  static SaleTransaction _mapTransaction(
    TransactionsTableData row, {
    int? itemCount,
    String? cashierName,
  }) => SaleTransaction(
    id: row.id,
    createdAt: row.createdAt,
    totalAmount: row.totalAmount,
    subtotal: row.subtotal,
    taxAmount: row.taxAmount,
    discountAmount: row.discountAmount,
    amountReceived: row.amountReceived,
    changeDue: row.changeDue,
    paymentMethod: row.paymentMethod,
    customerName: row.customerName,
    cashierId: row.cashierId,
    cashierName: cashierName,
    branchId: row.branchId,
    itemCount: itemCount ?? row.itemCount,
  );

  static SaleItem _mapItem(TransactionItemsTableData row) => SaleItem(
    transactionId: row.transactionId,
    productName: row.productName,
    variantName: row.variantName,
    qty: row.qty,
    unitPrice: row.unitPrice,
    lineTotal: row.lineTotal,
  );
}
