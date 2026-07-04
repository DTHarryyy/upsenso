import 'package:drift/drift.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/services/fraud_detection_engine.dart';
import 'package:pos/core/services/invoice_number_service.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';

/// Single, atomic entry point for completing a sale.
///
/// Recording the transaction and moving inventory used to be two separate
/// awaits inside the checkout widgets, so a crash between them left a sale with
/// no stock deduction (or vice-versa). This wraps both in one DB transaction so
/// a sale and its inventory impact always commit together — or not at all.
///
/// The saleCreated audit entry is written HERE, not by callers: every sale
/// path (POS checkout, legacy checkout, AI-created sales, anything future)
/// must land on the tamper-evident chain, and UI-side logging already missed
/// two of the three paths once.
class CheckoutService {
  final AppDatabase _db;
  final TransactionsDao _transactionsDao;
  final IInventoryRepository _inventoryRepository;
  final InvoiceNumberService _invoiceNumberService;
  final AuditLogService _auditLogService;
  final FraudDetectionEngine? _fraudEngine;

  CheckoutService({
    required AppDatabase db,
    required TransactionsDao transactionsDao,
    required IInventoryRepository inventoryRepository,
    required InvoiceNumberService invoiceNumberService,
    required AuditLogService auditLogService,
    FraudDetectionEngine? fraudEngine,
  })  : _db = db,
        _transactionsDao = transactionsDao,
        _inventoryRepository = inventoryRepository,
        _invoiceNumberService = invoiceNumberService,
        _auditLogService = auditLogService,
        _fraudEngine = fraudEngine;

  /// Persists [transaction] + [items] and deducts [deductions] atomically.
  /// Claims the next invoice number (server RPC when online, local counter
  /// when offline) and writes it into the companion before committing.
  ///
  /// [transactionId] must be the same id already set on [transaction] (the
  /// caller generates it up front to also stamp it on each item). It's
  /// threaded into the stock ledger entries so server-side RLS can verify
  /// each deduction traces back to this real sale.
  Future<String> completeSale({
    required TransactionsTableCompanion transaction,
    required List<TransactionItemsTableCompanion> items,
    required List<({String variantId, double qty})> deductions,
    required String businessId,
    required String? branchId,
    required String transactionId,
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
        sourceId: transactionId,
      );
    });

    // Post-commit, fire-and-forget: AuditLogService serializes and never
    // throws, so the sale's latency and success are unaffected.
    final total = _companionValue(transaction.totalAmount) ?? 0.0;
    _auditLogService.log(
      actionType: AuditLogActionType.saleCreated,
      entityType: 'transaction',
      entityId: transactionId,
      description:
          'Sale of ${AppFormatters.currency(total)} — ${items.length} item(s)',
      metadata: {
        'total': total,
        'subtotal': _companionValue(transaction.subtotal),
        'tax': _companionValue(transaction.taxAmount),
        'discount': _companionValue(transaction.discountAmount),
        'payment_method': _companionValue(transaction.paymentMethod),
        'item_count': items.length,
        'invoice_number': invoiceNumber,
        if (_companionValue(transaction.customerId) != null)
          'customer_id': _companionValue(transaction.customerId),
      },
      businessId: businessId,
      branchId: branchId,
      userId: _companionValue(transaction.cashierId),
    );

    _fraudEngine?.runIncremental(const {'HIGH_DISCOUNT'});

    return invoiceNumber;
  }

  T? _companionValue<T>(Value<T> v) => v.present ? v.value : null;
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
