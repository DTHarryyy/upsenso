import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/services/invoice_number_service.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';

/// Single, atomic entry point for completing a sale.
///
/// Recording the transaction and moving inventory used to be two separate
/// awaits inside the checkout widgets, so a crash between them left a sale with
/// no stock deduction (or vice-versa). This wraps both in one DB transaction so
/// a sale and its inventory impact always commit together — or not at all.
class CheckoutService {
  final AppDatabase _db;
  final TransactionsDao _transactionsDao;
  final IInventoryRepository _inventoryRepository;
  final InvoiceNumberService _invoiceNumberService;

  CheckoutService({
    required AppDatabase db,
    required TransactionsDao transactionsDao,
    required IInventoryRepository inventoryRepository,
    required InvoiceNumberService invoiceNumberService,
  })  : _db = db,
        _transactionsDao = transactionsDao,
        _inventoryRepository = inventoryRepository,
        _invoiceNumberService = invoiceNumberService;

  /// Persists [transaction] + [items] and deducts [deductions] atomically.
  /// Claims the next invoice number (server RPC when online, local counter
  /// when offline) and writes it into the companion before committing.
  Future<String> completeSale({
    required TransactionsTableCompanion transaction,
    required List<TransactionItemsTableCompanion> items,
    required List<({String variantId, double qty})> deductions,
    required String businessId,
    required String? branchId,
  }) async {
    // Claim the invoice number BEFORE opening the DB transaction so a server
    // roundtrip (when online) doesn't hold the SQLite write lock.
    final invoiceNumber = await _invoiceNumberService.claimNext(businessId);

    final txWithInvoice = transaction.copyWith(
      invoiceNumber: Value(invoiceNumber),
    );

    await _db.transaction(() async {
      // Validate stock inside the transaction so an oversell aborts the whole
      // sale rather than relying on adjustQuantity's silent clamp-to-zero,
      // which would record the sale while quietly under-deducting the ledger.
      final shortages = await _inventoryRepository.checkStockAvailability(
        items: deductions,
        branchId: branchId,
      );
      if (shortages.isNotEmpty) {
        throw InsufficientStockException(shortages);
      }

      await _transactionsDao.insertTransaction(txWithInvoice, items);
      await _inventoryRepository.recordSaleDeductions(
        items: deductions,
        businessId: businessId,
        branchId: branchId,
      );
    });

    return invoiceNumber;
  }
}

/// Raised when checkout is attempted with more quantity than available stock.
/// Carries the per-variant shortage detail so the UI can show a clear message.
class InsufficientStockException implements Exception {
  final List<({String variantId, double available, double requested})> shortages;

  const InsufficientStockException(this.shortages);

  @override
  String toString() =>
      'InsufficientStockException: ${shortages.length} item(s) short on stock';
}
