import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
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

  CheckoutService({
    required AppDatabase db,
    required TransactionsDao transactionsDao,
    required IInventoryRepository inventoryRepository,
  })  : _db = db,
        _transactionsDao = transactionsDao,
        _inventoryRepository = inventoryRepository;

  /// Persists [transaction] + [items] and deducts [deductions] atomically.
  Future<void> completeSale({
    required TransactionsTableCompanion transaction,
    required List<TransactionItemsTableCompanion> items,
    required List<({String variantId, double qty})> deductions,
    required String businessId,
    required String? branchId,
  }) async {
    await _db.transaction(() async {
      await _transactionsDao.insertTransaction(transaction, items);
      await _inventoryRepository.recordSaleDeductions(
        items: deductions,
        businessId: businessId,
        branchId: branchId,
      );
    });
  }
}
