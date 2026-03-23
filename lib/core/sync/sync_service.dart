import 'dart:async';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/models/business_model.dart';
import 'package:pos/features/products/data/datasources/products_remote_ds.dart';
import 'package:pos/features/pos/data/datasources/transactions_remote_ds.dart';

/// Service to handle synchronization between local Drift DB and Supabase
class SyncService {
  final AuthContextDao _authContextDao;
  final BusinessesDao _businessesDao;
  final CategoriesDao _categoriesDao;
  final ProductsDao _productsDao;
  final ProductVariantsDao _productVariantsDao;
  final TransactionsDao _transactionsDao;
  final BusinessRemoteDs _businessRemoteDs;
  final ProductsRemoteDs _productsRemoteDs;
  final TransactionsRemoteDs _transactionsRemoteDs;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required AuthContextDao authContextDao,
    required BusinessesDao businessesDao,
    required CategoriesDao categoriesDao,
    required ProductsDao productsDao,
    required ProductVariantsDao productVariantsDao,
    required TransactionsDao transactionsDao,
    required BusinessRemoteDs businessRemoteDs,
    required ProductsRemoteDs productsRemoteDs,
    required TransactionsRemoteDs transactionsRemoteDs,
    required ConnectivityService connectivityService,
  }) : _authContextDao = authContextDao,
       _businessesDao = businessesDao,
       _categoriesDao = categoriesDao,
       _productsDao = productsDao,
       _productVariantsDao = productVariantsDao,
       _transactionsDao = transactionsDao,
       _businessRemoteDs = businessRemoteDs,
       _productsRemoteDs = productsRemoteDs,
       _transactionsRemoteDs = transactionsRemoteDs,
       _connectivityService = connectivityService;

  /// Returns [provided] if non-null, otherwise reads businessId from the
  /// locally cached auth context. This allows connectivity-triggered syncs
  /// (which don't know the businessId) to still run the pull phase.
  Future<String?> _resolveBusinessId(String? provided) async {
    if (provided != null) return provided;
    final ctx = await _authContextDao.getAny();
    return ctx?.businessId;
  }

  /// Initialize sync service and listen for connectivity changes.
  /// On each reconnect: push pending local changes, then pull from server.
  void init() {
    // Sync immediately if already online at startup.
    _connectivityService.isConnected.then((online) {
      if (online) syncAll();
    });

    // sync whenever connectivity is restored.
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((isConnected) {
          if (isConnected) {
            syncAll();
          }
        });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// check kapag may internet connection
  Future<bool> get isOnline => _connectivityService.isConnected;

  /// reactive total couns ng pending sync records across all tables, for showing in UI.
  /// emits new value kapag may local change or sync status update in any of the tables.
  Stream<int> watchTotalPendingSyncCount() {
    int cat = 0, prod = 0, vars = 0, orders = 0;
    final controller = StreamController<int>.broadcast();

    void emit() {
      if (!controller.isClosed) controller.add(cat + prod + vars + orders);
    }

    final s1 = _categoriesDao.watchPendingSyncCount().listen((n) { cat = n; emit(); });
    final s2 = _productsDao.watchPendingSyncCount().listen((n) { prod = n; emit(); });
    final s3 = _productVariantsDao.watchPendingSyncCount().listen((n) { vars = n; emit(); });
    final s4 = _transactionsDao.watchPendingSyncCount().listen((n) { orders = n; emit(); });

    controller.onCancel = () {
      s1.cancel();
      s2.cancel();
      s3.cancel();
      s4.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// Push all pending local changes to Supabase, then pull from server.
  Future<SyncResult> syncAll({String? businessId}) async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    final online = await isOnline;
    if (!online) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    _isSyncing = true;

    try {
      // upload na here  bag o i pull
      final businessResult = await _syncBusinesses();
      final categoryResult = await _syncCategories();
      final productResult = await _syncProducts();
      final variantResult = await _syncProductVariants();
      final orderResult = await _syncTransactions();

      final int totalSynced = businessResult.syncedCount +
          categoryResult.syncedCount +
          productResult.syncedCount +
          variantResult.syncedCount +
          orderResult.syncedCount;
      final int totalFailed = businessResult.failedCount +
          categoryResult.failedCount +
          productResult.failedCount +
          variantResult.failedCount +
          orderResult.failedCount;

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
        success: businessResult.success &&
            categoryResult.success &&
            productResult.success &&
            variantResult.success &&
            pullResult.success,
        message:
            '${businessResult.message}; ${categoryResult.message}; ${productResult.message}; ${variantResult.message}; ${pullResult.message}',
        syncedCount: totalSynced + pullResult.syncedCount,
        failedCount: totalFailed + pullResult.failedCount,
        errors: [
          ...businessResult.errors,
          ...categoryResult.errors,
          ...productResult.errors,
          ...variantResult.errors,
          ...pullResult.errors,
        ],
      );
    } finally {
      _isSyncing = false;
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
              sortOrder: record.sortOrder,
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
              sortOrder: record.sortOrder,
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
              expiryDate: record.expiryDate,
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
              expiryDate: record.expiryDate,
              isActive: record.isActive,
            );
            await _productVariantsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _productsRemoteDs.deleteProductVariant(record.id);
            await _productVariantsDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e) {
        failed++;
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
          branchId: tx.branchId,
          totalAmount: tx.totalAmount,
          taxAmount: tx.taxAmount,
          createdAt: tx.createdAt,
        );
        await _transactionsDao.updateSyncStatus(
          id: tx.id,
          status: SyncStatus.synced,
        );
        synced++;
      } catch (e) {
        failed++;
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

    return SyncResult(
      success: failed == 0,
      message: 'Pull: $pulled records, $failed errors',
      syncedCount: pulled,
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
