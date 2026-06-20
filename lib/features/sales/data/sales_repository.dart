import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/refunds_dao.dart';
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
  final AuthContextDao _authContextDao;
  final RefundsDao _refundsDao;
  final ProductVariantsDao _variantsDao;
  final ProductsDao _productsDao;

  const SalesRepository(
    this._txDao,
    this._employeesDao,
    this._authContextDao,
    this._refundsDao,
    this._variantsDao,
    this._productsDao,
  );

  @override
  Stream<List<SaleTransaction>> watchTransactions({
    String? branchId,
  }) => _txDao.watchTransactions(branchId: branchId).asyncMap((rows) async {
    final ids = rows.map((r) => r.id).toList();
    final counts = await _txDao.getItemCountsForTransactions(ids);
    final refundedAmounts = await _refundsDao.getRefundedAmountForTransactions(
      ids,
    );
    final cashierIds = rows
        .map((r) => r.cashierId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    // Primary lookup: employees table (covers all staff).
    var cashierNames = await _employeesDao.getNamesForAuthUserIds(cashierIds);
    // Fallback: auth_context table for any IDs still unresolved — covers the
    // business owner, who is not stored as an employee on this device.
    final unresolved =
        cashierIds.where((id) => !cashierNames.containsKey(id)).toList();
    if (unresolved.isNotEmpty) {
      final fallback = await _authContextDao.getNamesForUserIds(unresolved);
      cashierNames = {...cashierNames, ...fallback};
    }
    return rows.map((r) {
      // Use actual count from transaction_items; fall back to stored
      // itemCount only if no items exist yet (brand-new transaction
      // not yet committed to the items table).
      final realCount = counts.containsKey(r.id) ? counts[r.id]! : r.itemCount;
      return _mapTransaction(
        r,
        itemCount: realCount,
        cashierName: cashierNames[r.cashierId],
        refundedAmount: refundedAmounts[r.id] ?? 0.0,
      );
    }).toList();
  });

  @override
  Future<List<SaleItem>> getTransactionItems(String transactionId) async {
    final rows = await _txDao.getItemsByTransactionId(transactionId);
    final refundedQty = await _refundsDao.getRefundedQtyByTransactionId(
      transactionId,
    );

    final variantIds = rows.map((r) => r.variantId).toSet().toList();
    final variants = await _variantsDao.getByIds(variantIds);
    final variantById = {for (final v in variants) v.id: v};
    final productIds = variants.map((v) => v.productId).toSet().toList();
    final products = await _productsDao.getByIds(productIds);
    final trackingMethodByProductId = {
      for (final p in products) p.id: p.trackingMethod,
    };

    return rows
        .map(
          (r) => _mapItem(
            r,
            refundedQty: refundedQty[r.id] ?? 0.0,
            isStockTracked: _isStockTracked(
              variantById[r.variantId],
              trackingMethodByProductId,
            ),
          ),
        )
        .toList();
  }

  /// Mirrors the same branch [InventoryRepository.reverseSaleDeductions]
  /// uses to decide whether a refund line can actually move stock — `service`
  /// products never can; `recipe` products always can (ingredients move
  /// regardless of the finished variant's own trackStock); a plain
  /// `product_stock` variant can only if its trackStock flag is on.
  static bool _isStockTracked(
    ProductVariantsTableData? variant,
    Map<String, String> trackingMethodByProductId,
  ) {
    if (variant == null) return false;
    final method = trackingMethodByProductId[variant.productId] ?? 'product_stock';
    return switch (method) {
      'service' => false,
      'recipe' => true,
      _ => variant.trackStock,
    };
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  static SaleTransaction _mapTransaction(
    TransactionsTableData row, {
    int? itemCount,
    String? cashierName,
    double refundedAmount = 0.0,
  }) => SaleTransaction(
    id: row.id,
    invoiceNumber: row.invoiceNumber,
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
    status: row.status,
    refundedAmount: refundedAmount,
  );

  static SaleItem _mapItem(
    TransactionItemsTableData row, {
    double refundedQty = 0.0,
    bool isStockTracked = true,
  }) => SaleItem(
    id: row.id,
    transactionId: row.transactionId,
    variantId: row.variantId,
    productName: row.productName,
    variantName: row.variantName,
    qty: row.qty,
    unitPrice: row.unitPrice,
    lineTotal: row.lineTotal,
    refundedQty: refundedQty,
    isStockTracked: isStockTracked,
  );
}
