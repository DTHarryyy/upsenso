import 'package:pos/core/database/app_database.dart';
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

  const SalesRepository(this._txDao);

  @override
  Stream<List<SaleTransaction>> watchTransactions({String? branchId}) => _txDao
      .watchTransactions(branchId: branchId)
      .map((rows) => rows.map(_mapTransaction).toList());

  @override
  Future<List<SaleItem>> getTransactionItems(String transactionId) async {
    final rows = await _txDao.getItemsByTransactionId(transactionId);
    return rows.map(_mapItem).toList();
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  static SaleTransaction _mapTransaction(TransactionsTableData row) =>
      SaleTransaction(
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
        branchId: row.branchId,
        itemCount: row.itemCount,
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
