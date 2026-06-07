import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/expenses_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/models/business_model.dart';
import 'package:pos/features/business/domain/entities/branch.dart';
import 'package:pos/features/expenses/data/datasources/expenses_remote_ds.dart';
import 'package:pos/features/products/data/datasources/products_remote_ds.dart';
import 'package:pos/features/pos/data/datasources/transactions_remote_ds.dart';
import 'package:pos/features/settings/data/receipt_settings_repository.dart';
import 'package:pos/features/audit_logs/data/datasources/audit_log_remote_ds.dart';
import 'package:pos/features/employees/data/datasources/employees_remote_ds.dart';

/// Service to handle synchronization between local Drift DB and Supabase
class SyncService {
  final AuthContextDao _authContextDao;
  final BranchesDao _branchesDao;
  final BusinessesDao _businessesDao;
  final CategoriesDao _categoriesDao;
  final ExpensesDao _expensesDao;
  final InventoryLevelsDao _inventoryLevelsDao;
  final ProductsDao _productsDao;
  final ProductVariantsDao _productVariantsDao;
  final StockLedgerDao _stockLedgerDao;
  final TransactionsDao _transactionsDao;
  final BusinessRemoteDs _businessRemoteDs;
  final ExpensesRemoteDs _expensesRemoteDs;
  final ProductsRemoteDs _productsRemoteDs;
  final TransactionsRemoteDs _transactionsRemoteDs;
  final ConnectivityService _connectivityService;
  final ReceiptSettingsRepository _receiptSettingsRepo;
  final AuditLogsDao _auditLogsDao;
  final AuditLogRemoteDs _auditLogRemoteDs;
  final EmployeesDao _employeesDao;
  final EmployeesRemoteDs _employeesRemoteDs;

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _isSyncing = false;
  bool _initCalled = false;
  // Holds the most recent businessId provided to syncAll() while a sync was
  // already running. After the current sync finishes we re-run pullFromServer
  // with this id so no data is missed.
  String? _pendingBusinessId;

  SyncService({
    required AuthContextDao authContextDao,
    required BranchesDao branchesDao,
    required BusinessesDao businessesDao,
    required CategoriesDao categoriesDao,
    required ExpensesDao expensesDao,
    required InventoryLevelsDao inventoryLevelsDao,
    required ProductsDao productsDao,
    required ProductVariantsDao productVariantsDao,
    required StockLedgerDao stockLedgerDao,
    required TransactionsDao transactionsDao,
    required BusinessRemoteDs businessRemoteDs,
    required ExpensesRemoteDs expensesRemoteDs,
    required ProductsRemoteDs productsRemoteDs,
    required TransactionsRemoteDs transactionsRemoteDs,
    required ConnectivityService connectivityService,
    required ReceiptSettingsRepository receiptSettingsRepository,
    required AuditLogsDao auditLogsDao,
    required AuditLogRemoteDs auditLogRemoteDs,
    required EmployeesDao employeesDao,
    required EmployeesRemoteDs employeesRemoteDs,
  }) : _authContextDao = authContextDao,
       _branchesDao = branchesDao,
       _businessesDao = businessesDao,
       _categoriesDao = categoriesDao,
       _expensesDao = expensesDao,
       _inventoryLevelsDao = inventoryLevelsDao,
       _productsDao = productsDao,
       _productVariantsDao = productVariantsDao,
       _stockLedgerDao = stockLedgerDao,
       _transactionsDao = transactionsDao,
       _businessRemoteDs = businessRemoteDs,
       _expensesRemoteDs = expensesRemoteDs,
       _productsRemoteDs = productsRemoteDs,
       _transactionsRemoteDs = transactionsRemoteDs,
       _connectivityService = connectivityService,
       _receiptSettingsRepo = receiptSettingsRepository,
       _auditLogsDao = auditLogsDao,
       _auditLogRemoteDs = auditLogRemoteDs,
       _employeesDao = employeesDao,
       _employeesRemoteDs = employeesRemoteDs;

  /// Returns [provided] if non-null, otherwise reads businessId from the
  /// locally cached auth context. This allows connectivity-triggered syncs
  /// (which don't know the businessId) to still run the pull phase.
  Future<String?> _resolveBusinessId(String? provided) async {
    if (provided != null) return provided;
    final ctx = await _authContextDao.getAny();
    return ctx?.businessId;
  }

  /// Initialize sync service and listen for connectivity changes.
  /// Guards against being called multiple times (e.g. if MainNavigationPage
  /// is rebuilt) so we never accumulate duplicate listeners.
  void init() {
    if (_initCalled) return;
    _initCalled = true;

    // Sync immediately if already online at startup.
    _connectivityService.isConnected.then((online) {
      if (online) syncAll();
    });

    // Sync whenever connectivity is restored.
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((isConnected) {
          if (isConnected) syncAll();
        });

    // Periodic retry every 60 s so that a failed initial sync doesn't leave
    // data pending forever (which would otherwise require a connectivity change
    // or app restart to trigger another attempt).
    _retryTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      syncAll().ignore();
    });
  }

  void dispose() {
    _retryTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Wipe all business-specific local data on logout so the next account
  /// starts with a clean slate. Called before emitting AuthUnauthenticated.
  Future<void> clearLocalData() async {
    await _inventoryLevelsDao.clearAll();
    await _stockLedgerDao.clearAll();
    await _expensesDao.clearAll();
    await _transactionsDao.clearAll();
    await _productVariantsDao.clearAll();
    await _productsDao.clearAll();
    await _categoriesDao.clearAll();
    await _branchesDao.clearAll();
    await _businessesDao.clearAll();
    await _receiptSettingsRepo.clearAll();
    await _auditLogsDao.clearAll();
    await _employeesDao.clearAll();
    await _authContextDao.clearAll();
  }

  /// check kapag may internet connection
  Future<bool> get isOnline => _connectivityService.isConnected;

  /// Reactive total count of pending sync records across ALL tables.
  Stream<int> watchTotalPendingSyncCount() {
    int cat = 0,
        prod = 0,
        vars = 0,
        orders = 0,
        exp = 0,
        inv = 0,
        led = 0,
        rcpt = 0,
        audit = 0,
        emp = 0;
    final controller = StreamController<int>.broadcast();

    void emit() {
      if (!controller.isClosed) {
        controller.add(
          cat + prod + vars + orders + exp + inv + led + rcpt + audit + emp,
        );
      }
    }

    final s1 = _categoriesDao.watchPendingSyncCount().listen((n) {
      cat = n;
      emit();
    });
    final s2 = _productsDao.watchPendingSyncCount().listen((n) {
      prod = n;
      emit();
    });
    final s3 = _productVariantsDao.watchPendingSyncCount().listen((n) {
      vars = n;
      emit();
    });
    final s4 = _transactionsDao.watchPendingSyncCount().listen((n) {
      orders = n;
      emit();
    });
    final s5 = _expensesDao.watchPendingSyncCount().listen((n) {
      exp = n;
      emit();
    });
    final s6 = _inventoryLevelsDao.watchPendingSyncCount().listen((n) {
      inv = n;
      emit();
    });
    final s7 = _stockLedgerDao.watchPendingSyncCount().listen((n) {
      led = n;
      emit();
    });
    // ignore: avoid_function_literals_in_foreach_calls — DAO doesn't expose stream directly
    final s8 = _receiptSettingsRepo.watchPendingSyncCount().listen((n) {
      rcpt = n;
      emit();
    });
    final s9 = _auditLogsDao.watchPendingSyncCount().listen((n) {
      audit = n;
      emit();
    });
    final s10 = _employeesDao.watchPendingSyncCount().listen((n) {
      emp = n;
      emit();
    });

    controller.onCancel = () {
      s1.cancel();
      s2.cancel();
      s3.cancel();
      s4.cancel();
      s5.cancel();
      s6.cancel();
      s7.cancel();
      s8.cancel();
      s9.cancel();
      s10.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// Push all pending local changes to Supabase, then pull from server.
  Future<SyncResult> syncAll({String? businessId}) async {
    if (_isSyncing) {
      // If the caller provided a businessId, keep it so the running sync (or
      // the follow-up pull after it) can use it.  This prevents the common
      // startup race where AuthBloc calls syncAll(businessId: id) while
      // SyncService.init() already kicked off a no-businessId syncAll().
      if (businessId != null) _pendingBusinessId = businessId;
      return SyncResult(success: false, message: 'Sync already in progress');
    }
    // Set the flag immediately — before any await — so concurrent calls that
    // arrive during the isOnline check are correctly blocked.
    _isSyncing = true;
    // Capture and clear any pending businessId queued during a prior sync.
    final queued = _pendingBusinessId;
    _pendingBusinessId = null;
    // Prefer the explicitly-provided businessId; fall back to the queued one.
    businessId ??= queued;

    final online = await isOnline;
    if (!online) {
      _isSyncing = false;
      return SyncResult(success: false, message: 'No internet connection');
    }

    try {
      // upload na here  bag o i pull
      final businessResult = await _syncBusinesses();
      final categoryResult = await _syncCategories();
      final productResult = await _syncProducts();
      final variantResult = await _syncProductVariants();
      final orderResult = await _syncTransactions();
      final expenseResult = await _syncExpenses();
      final inventoryResult = await _syncInventoryLevels();
      final ledgerResult = await _syncStockLedger();
      await _syncReceiptSettings(); // fire-and-forget style; errors logged internally
      await _syncAuditLogs(); // fire-and-forget style; errors logged internally
      final employeeResult = await _syncEmployees();

      final int totalSynced =
          businessResult.syncedCount +
          categoryResult.syncedCount +
          productResult.syncedCount +
          variantResult.syncedCount +
          orderResult.syncedCount +
          expenseResult.syncedCount +
          inventoryResult.syncedCount +
          ledgerResult.syncedCount +
          employeeResult.syncedCount;
      final int totalFailed =
          businessResult.failedCount +
          categoryResult.failedCount +
          productResult.failedCount +
          variantResult.failedCount +
          orderResult.failedCount +
          expenseResult.failedCount +
          inventoryResult.failedCount +
          ledgerResult.failedCount +
          employeeResult.failedCount;

      // pull kapag may businessId (either provided or from auth context)
      final effectiveBusinessId = await _resolveBusinessId(businessId);
      SyncResult pullResult = SyncResult(
        success: true,
        message: 'Pull skipped (no businessId)',
      );
      if (effectiveBusinessId != null) {
        pullResult = await pullFromServer(effectiveBusinessId);
      }

      return SyncResult(
        success:
            businessResult.success &&
            categoryResult.success &&
            productResult.success &&
            variantResult.success &&
            expenseResult.success &&
            inventoryResult.success &&
            ledgerResult.success &&
            employeeResult.success &&
            pullResult.success,
        message:
            '${businessResult.message}; ${categoryResult.message}; ${productResult.message}; ${variantResult.message}; ${expenseResult.message}; ${inventoryResult.message}; ${ledgerResult.message}; ${employeeResult.message}; ${pullResult.message}',
        syncedCount: totalSynced + pullResult.syncedCount,
        failedCount: totalFailed + pullResult.failedCount,
        errors: [
          ...businessResult.errors,
          ...categoryResult.errors,
          ...productResult.errors,
          ...variantResult.errors,
          ...expenseResult.errors,
          ...inventoryResult.errors,
          ...ledgerResult.errors,
          ...employeeResult.errors,
          ...pullResult.errors,
        ],
      );
    } finally {
      _isSyncing = false;
      // If a sync call with a businessId arrived while we were running (e.g.
      // AuthBloc._backgroundSync during the startup init sync), schedule a
      // quick pull-only pass so that server data is never missed.
      final followUp = _pendingBusinessId;
      if (followUp != null) {
        _pendingBusinessId = null;
        _connectivityService.isConnected.then((online) {
          if (online) pullFromServer(followUp).ignore();
        });
      }
    }
  }

  // i sync na yung categories

  Future<SyncResult> _syncCategories() async {
    final pending = await _categoriesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _businessRemoteDs.createCategory(
              id: record.id,
              businessId: record.businessId,
              name: record.name,
            );
            await _categoriesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingUpdate:
            await _businessRemoteDs.updateCategory(
              id: record.id,
              name: record.name,
            );
            await _categoriesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _businessRemoteDs.deleteCategory(record.id);
            await _categoriesDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e) {
        failed++;
        debugPrint('[SYNC] Category ${record.name} FAILED: $e');
        errors.add('Category ${record.name}: ${e.toString()}');
        await _categoriesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Categories: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // i sync namn yung mga products

  Future<SyncResult> _syncProducts() async {
    final pending = await _productsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _productsRemoteDs.createProduct(
              id: record.id,
              businessId: record.businessId,
              categoryId: record.categoryId,
              name: record.name,
              sku: record.sku,
              barcode: record.barcode,
              tax: record.tax,
              sellBy: record.sellBy,
              hasVariants: record.hasVariants,
              isActive: record.isActive,
            );
            await _productsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingUpdate:
            await _productsRemoteDs.updateProduct(
              id: record.id,
              categoryId: record.categoryId,
              name: record.name,
              sku: record.sku,
              barcode: record.barcode,
              tax: record.tax,
              sellBy: record.sellBy,
              hasVariants: record.hasVariants,
              isActive: record.isActive,
            );
            await _productsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _productsRemoteDs.deleteProduct(record.id);
            await _productsDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e) {
        failed++;
        debugPrint('[SYNC] Product ${record.name} FAILED: $e');
        errors.add('Product ${record.name}: ${e.toString()}');
        await _productsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Products: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // sycn naman mga products variants

  Future<SyncResult> _syncProductVariants() async {
    final pending = await _productVariantsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _productsRemoteDs.createProductVariant(
              id: record.id,
              productId: record.productId,
              businessId: record.businessId,
              name: record.name,
              price: record.price,
              costPrice: record.costPrice,
              retailPrice: record.retailPrice,
              stock: record.stock,
              sku: record.sku,
              barcode: record.barcode,
              stockDecimal: record.stockDecimal,
              trackExpiry: record.trackExpiry,
              expiryDate: record.expiryDate?.millisecondsSinceEpoch,
              isActive: record.isActive,
            );
            await _productVariantsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingUpdate:
            await _productsRemoteDs.updateProductVariant(
              id: record.id,
              name: record.name,
              price: record.price,
              costPrice: record.costPrice,
              retailPrice: record.retailPrice,
              stock: record.stock,
              sku: record.sku,
              barcode: record.barcode,
              trackExpiry: record.trackExpiry,
              expiryDate: record.expiryDate?.millisecondsSinceEpoch,
              isActive: record.isActive,
            );
            await _productVariantsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            try {
              await _productsRemoteDs.deleteProductVariant(record.id);
            } on PostgrestException catch (e) {
              if (e.code == '23503') {
                // Still referenced by transaction_items / stock_ledger /
                // inventory_levels — soft-delete instead so history is intact.
                await _productsRemoteDs.softDeleteProductVariant(record.id);
              } else {
                rethrow;
              }
            }
            await _productVariantsDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e) {
        failed++;
        debugPrint('[SYNC] Variant ${record.name} FAILED: $e');
        errors.add('Variant ${record.name}: ${e.toString()}');
        await _productVariantsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Variants: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // sync completed POS transactions — upload only (transactions are immutable)

  Future<SyncResult> _syncTransactions() async {
    final pending = await _transactionsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final tx in pending) {
      try {
        await _transactionsRemoteDs.createTransaction(
          id: tx.id,
          cashierId: tx.cashierId,
          businessId: tx.businessId,
          branchId: tx.branchId,
          totalAmount: tx.totalAmount,
          discountAmount: tx.discountAmount,
          taxAmount: tx.taxAmount,
          createdAt: tx.createdAt,
          paymentMethod: tx.paymentMethod,
        );
        final items = await _transactionsDao.getItemsByTransactionId(tx.id);
        if (items.isNotEmpty) {
          await _transactionsRemoteDs.upsertTransactionItems(
            items
                .map(
                  (i) => {
                    'id': i.id,
                    'transaction_id': i.transactionId,
                    'variant_id': i.variantId,
                    'product_name': i.productName,
                    'variant_name': i.variantName,
                    'unit_price': i.unitPrice,
                    'tax_rate': i.taxRate,
                    'qty': i.qty,
                    'line_total': i.lineTotal,
                    'line_tax': i.lineTax,
                  },
                )
                .toList(),
          );
        }
        await _transactionsDao.updateSyncStatus(
          id: tx.id,
          status: SyncStatus.synced,
        );
        synced++;
      } catch (e) {
        // FK violation: a referenced variant is missing from Supabase.
        // Reset all variants in this transaction's items to pendingUpload
        // so the next cycle re-uploads them before retrying the transaction.
        if (e is PostgrestException && e.code == '23503') {
          final items = await _transactionsDao.getItemsByTransactionId(tx.id);
          for (final item in items) {
            await _productVariantsDao.updateSyncStatus(
              id: item.variantId,
              status: SyncStatus.pendingUpload,
            );
          }
          debugPrint(
            '[SYNC] Transaction ${tx.id}: variant missing on server, re-queuing variants for upload',
          );
          continue;
        }
        failed++;
        debugPrint('[SYNC] Transaction ${tx.id} FAILED: $e');
        errors.add('Transaction ${tx.id}: ${e.toString()}');
        await _transactionsDao.updateSyncStatus(
          id: tx.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Transactions: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncExpenses() async {
    final pending = await _expensesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _expensesRemoteDs.upsertExpense(
              id: record.id,
              businessId: record.businessId,
              branchId: record.branchId,
              branchName: record.branchName,
              category: record.category,
              vendor: record.vendor,
              amount: record.amount,
              status: record.status,
              submittedById: record.submittedById,
              submittedByName: record.submittedByName,
              approvedById: record.approvedById,
              approvedByName: record.approvedByName,
              note: record.note,
              expenseDate: record.expenseDate,
              createdAt: record.createdAt,
              updatedAt: record.updatedAt,
            );
            await _expensesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingUpdate:
            await _expensesRemoteDs.updateExpenseStatus(
              id: record.id,
              status: record.status,
              approvedById: record.approvedById,
              approvedByName: record.approvedByName,
              updatedAt: record.updatedAt,
            );
            await _expensesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _expensesRemoteDs.deleteExpense(record.id);
            await _expensesDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e) {
        failed++;
        debugPrint('[SYNC] Expense ${record.id} FAILED: $e');
        errors.add('Expense ${record.id}: ${e.toString()}');
        await _expensesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Expenses: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncInventoryLevels() async {
    final pending = await _inventoryLevelsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      try {
        await _productsRemoteDs.upsertInventoryLevel(
          id: record.id,
          variantId: record.variantId,
          branchId: record.branchId,
          businessId: record.businessId,
          quantity: record.quantity,
          quantityDecimal: record.quantityDecimal,
          lowStockAlertOverride: record.lowStockAlertOverride,
        );
        await _inventoryLevelsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.synced,
        );
        synced++;
      } catch (e) {
        // FK violation: variant is locally marked synced but missing from Supabase
        // (e.g. remote DB was reset). Reset it to pendingUpload so the next cycle
        // re-uploads it before retrying this inventory level.
        if (e is PostgrestException && e.code == '23503') {
          await _productVariantsDao.updateSyncStatus(
            id: record.variantId,
            status: SyncStatus.pendingUpload,
          );
          debugPrint(
            '[SYNC] InventoryLevel ${record.id}: variant missing on server, re-queuing variant for upload',
          );
          continue;
        }
        failed++;
        debugPrint('[SYNC] InventoryLevel ${record.id} FAILED: $e');
        errors.add('InventoryLevel ${record.id}: ${e.toString()}');
        await _inventoryLevelsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'InventoryLevels: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncStockLedger() async {
    final pending = await _stockLedgerDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      try {
        await _productsRemoteDs.insertStockLedgerEntry(
          id: record.id,
          variantId: record.variantId,
          productId: record.productId,
          branchId: record.branchId,
          businessId: record.businessId,
          changeType: record.changeType,
          quantity: record.quantity,
          quantityBefore: record.quantityBefore,
          quantityAfter: record.quantityAfter,
          reason: record.reason,
          note: record.note,
          createdAt: record.createdAt,
        );
        await _stockLedgerDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.synced,
        );
        synced++;
      } catch (e) {
        // FK violation: variant or product is locally synced but missing from
        // Supabase. Reset the parent(s) to pendingUpload for self-healing.
        if (e is PostgrestException && e.code == '23503') {
          await _productVariantsDao.updateSyncStatus(
            id: record.variantId,
            status: SyncStatus.pendingUpload,
          );
          await _productsDao.updateSyncStatus(
            id: record.productId,
            status: SyncStatus.pendingUpload,
          );
          debugPrint(
            '[SYNC] StockLedger ${record.id}: parent missing on server, re-queuing variant/product for upload',
          );
          continue;
        }
        failed++;
        debugPrint('[SYNC] StockLedger ${record.id} FAILED: $e');
        errors.add('StockLedger ${record.id}: ${e.toString()}');
        await _stockLedgerDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'StockLedger: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // i sync na yung businesses, kahit isa lang dapat yun pero for consistency with other tables we still loop through pending records list

  Future<SyncResult> _syncBusinesses() async {
    final pendingRecords = await _businessesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pendingRecords) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);

      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _handlePendingUpload(record);
            synced++;

          case SyncStatus.pendingUpdate:
            await _handlePendingUpdate(record);
            synced++;

          case SyncStatus.pendingDelete:
            await _handlePendingDelete(record);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e) {
        failed++;
        errors.add('${record.name}: ${e.toString()}');
        await _businessesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Businesses: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<void> _handlePendingUpload(BusinessesTableData record) async {
    await _businessRemoteDs.createBusiness(
      id: record.id,
      name: record.name,
      ownerId: record.ownerId,
      templateId: record.templateId,
    );
    await _businessesDao.updateSyncStatus(
      id: record.id,
      status: SyncStatus.synced,
    );
  }

  Future<void> _handlePendingUpdate(BusinessesTableData record) async {
    await _businessesDao.updateSyncStatus(
      id: record.id,
      status: SyncStatus.synced,
    );
  }

  Future<void> _handlePendingDelete(BusinessesTableData record) async {
    await _businessesDao.hardDelete(record.id);
  }

  // pull the data from sever kapag  bago ang device or may changes sa server that are not yet in local db, then update local db with server data. This ensures na kahit connectivity-triggered syncs on a new device still pull server data.
  Future<SyncResult> pullFromServer(String businessId) async {
    final online = await isOnline;
    if (!online) {
      return SyncResult(success: false, message: 'Pull skipped: offline');
    }

    int pulled = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      final categories = await _businessRemoteDs.getCategoriesByBusiness(
        businessId,
      );
      for (final row in categories) {
        await _categoriesDao.upsertFromServer(row);
        pulled++;
      }
    } catch (e) {
      failed++;
      errors.add('Pull categories: ${e.toString()}');
    }

    try {
      final products = await _productsRemoteDs.getProductsByBusiness(
        businessId,
      );
      for (final row in products) {
        await _productsDao.upsertFromServer(row);
        pulled++;
      }
    } catch (e) {
      failed++;
      errors.add('Pull products: ${e.toString()}');
    }

    // // pull ang variants
    try {
      final variants = await _productsRemoteDs.getVariantsByBusiness(
        businessId,
      );
      for (final row in variants) {
        await _productVariantsDao.upsertFromServer(row);
        pulled++;
      }
    } catch (e) {
      failed++;
      errors.add('Pull variants: ${e.toString()}');
    }

    try {
      final levels = await _productsRemoteDs.getInventoryLevelsByBusiness(
        businessId,
      );
      for (final row in levels) {
        await _inventoryLevelsDao.upsertFromServer(row);
        pulled++;
      }
    } catch (e) {
      failed++;
      errors.add('Pull inventory levels: ${e.toString()}');
    }

    try {
      final ledger = await _productsRemoteDs.getStockLedgerByBusiness(
        businessId,
      );
      for (final row in ledger) {
        await _stockLedgerDao.upsertFromServer(row);
        pulled++;
      }
    } catch (e) {
      failed++;
      errors.add('Pull stock ledger: ${e.toString()}');
    }

    try {
      final transactions = await _transactionsRemoteDs
          .getTransactionsByBusiness(businessId);
      for (final row in transactions) {
        await _transactionsDao.upsertFromServer(row);
        pulled++;
      }
      // Pull line items for all transactions so dashboard top-items & reports work.
      final items = await _transactionsRemoteDs.getItemsByBusiness(businessId);
      for (final item in items) {
        await _transactionsDao.upsertItemFromServer(item);
        pulled++;
      }
    } catch (e) {
      failed++;
      errors.add('Pull transactions: ${e.toString()}');
    }

    try {
      final expenses = await _expensesRemoteDs.getExpensesByBusiness(
        businessId,
      );
      for (final row in expenses) {
        await _expensesDao.upsertFromServer(row);
        pulled++;
      }
    } catch (e) {
      failed++;
      errors.add('Pull expenses: ${e.toString()}');
    }

    try {
      final branches = await _businessRemoteDs.getActiveBranchesByBusiness(
        businessId,
      );
      for (final row in branches) {
        await _branchesDao.upsertFromServer(
          Branch(
            id: row['id'] as String,
            businessId: row['business_id'] as String,
            name: row['name'] as String,
            location: row['location'] as String?,
          ),
        );
        pulled++;
      }
    } catch (e) {
      failed++;
      errors.add('Pull branches: ${e.toString()}');
    }

    try {
      final businessData = await _businessRemoteDs.getBusinessById(businessId);
      if (businessData != null) {
        await _businessesDao.upsertFromServer(
          BusinessModel.fromJson(businessData),
        );
        pulled++;
      }
    } catch (e) {
      failed++;
      errors.add('Pull business: ${e.toString()}');
    }

    try {
      await _receiptSettingsRepo.pullFromServer(businessId);
      pulled++;
    } catch (e) {
      failed++;
      errors.add('Pull receipt settings: ${e.toString()}');
    }

    try {
      final employees = await _employeesRemoteDs.getEmployeesByBusiness(
        businessId,
      );
      for (final row in employees) {
        final rowId = row['id'] as String;
        // Do not overwrite records that have pending local changes.
        // They will be pushed by _syncEmployees() on the next sync cycle,
        // so the server will receive the correct data. Overwriting here would
        // silently discard offline edits made on this device.
        final existing = await _employeesDao.getById(rowId);
        if (existing != null &&
            _hasPendingEmployeeChanges(existing.syncStatus)) {
          continue;
        }
        // Extract denormalized branch from employee_branches join
        final branches = row['employee_branches'] as List?;
        final branchId = branches != null && branches.isNotEmpty
            ? branches.first['branch_id'] as String?
            : null;
        final roleName = row['roles'] != null
            ? (row['roles'] as Map<String, dynamic>)['name'] as String?
            : null;

        await _employeesDao.upsertFromServer(
          EmployeesTableCompanion.insert(
            id: row['id'] as String,
            businessId: row['business_id'] as String,
            userId: Value(row['user_id'] as String?),
            authUserId: Value(row['auth_user_id'] as String?),
            fullName: Value(row['full_name'] as String?),
            roleId: Value(row['role_id'] as String?),
            roleName: Value(roleName),
            branchId: Value(branchId),
            isActive: Value((row['is_active'] as bool?) ?? true),
            createdAt: Value(
              row['created_at'] != null
                  ? DateTime.parse(row['created_at'] as String)
                  : null,
            ),
            syncStatus: const Value(3), // synced
          ),
        );
        pulled++;
      }
    } catch (e) {
      failed++;
      errors.add('Pull employees: ${e.toString()}');
    }

    return SyncResult(
      success: failed == 0,
      message: 'Pull: $pulled records, $failed errors',
      syncedCount: pulled,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<void> _syncReceiptSettings() async {
    try {
      await _receiptSettingsRepo.syncPending();
    } catch (e) {
      debugPrint('[SYNC] Receipt settings push failed: $e');
    }
  }

  Future<void> _syncAuditLogs() async {
    try {
      final pending = await _auditLogsDao.getPendingSync();
      if (pending.isEmpty) return;

      final rows = pending
          .map(
            (r) => {
              'id': r.id,
              'business_id': r.businessId,
              'branch_id': r.branchId.isEmpty ? null : r.branchId,
              'user_id': r.userId.isEmpty ? null : r.userId,
              'action_type': r.actionType,
              'entity_type': r.entityType,
              'entity_id': (r.entityId?.isEmpty ?? true) ? null : r.entityId,
              'description': r.description,
              'metadata': r.metadata,
              'device_id': r.deviceId,
              'created_at': r.createdAt.toUtc().toIso8601String(),
            },
          )
          .toList();

      await _auditLogRemoteDs.upsertLogs(rows);

      for (final r in pending) {
        await _auditLogsDao.updateSyncStatus(
          id: r.id,
          status: SyncStatus.synced,
        );
      }
      debugPrint('[SYNC] Audit logs: pushed ${pending.length}');
    } catch (e) {
      debugPrint('[SYNC] Audit logs push failed: $e');
    }
  }

  Future<SyncResult> _syncEmployees() async {
    final pending = await _employeesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
          case SyncStatus.pendingUpdate:
            await _employeesRemoteDs.upsertEmployee(
              id: record.id,
              businessId: record.businessId,
              userId: record.userId,
              authUserId: record.authUserId,
              fullName: record.fullName ?? '',
              roleId: record.roleId,
              isActive: record.isActive,
            );
            if (record.branchId != null) {
              await _employeesRemoteDs.assignBranch(
                employeeId: record.id,
                branchId: record.branchId!,
              );
            }
            await _employeesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _employeesRemoteDs.deleteEmployee(record.id);
            await _employeesDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e) {
        failed++;
        debugPrint('[SYNC] Employee ${record.fullName} FAILED: $e');
        errors.add('Employee ${record.fullName}: ${e.toString()}');
        await _employeesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Employees: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  /// Pull latest business data from server and update local DB.
  Future<void> pullBusinessFromServer(String ownerId) async {
    final online = await isOnline;
    if (!online) return;

    final serverData = await _businessRemoteDs.getBusinessByOwner(ownerId);
    if (serverData != null) {
      final business = BusinessModel.fromJson(serverData);
      await _businessesDao.upsertFromServer(business);
    }
  }

  /// Returns true when [syncStatus] represents a locally pending change that
  /// must be uploaded before server data may overwrite it.
  bool _hasPendingEmployeeChanges(int syncStatus) {
    return syncStatus == SyncStatus.pendingUpload.toInt() ||
        syncStatus == SyncStatus.pendingUpdate.toInt() ||
        syncStatus == SyncStatus.pendingDelete.toInt();
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
  });
}
