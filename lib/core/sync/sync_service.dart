import 'dart:async';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/models/business_model.dart';
import 'package:pos/features/products/data/datasources/products_remote_ds.dart';

/// Service to handle synchronization between local Drift DB and Supabase
class SyncService {
  final BusinessesDao _businessesDao;
  final CategoriesDao _categoriesDao;
  final ProductsDao _productsDao;
  final ProductVariantsDao _productVariantsDao;
  final BusinessRemoteDs _businessRemoteDs;
  final ProductsRemoteDs _productsRemoteDs;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required BusinessesDao businessesDao,
    required CategoriesDao categoriesDao,
    required ProductsDao productsDao,
    required ProductVariantsDao productVariantsDao,
    required BusinessRemoteDs businessRemoteDs,
    required ProductsRemoteDs productsRemoteDs,
    required ConnectivityService connectivityService,
  }) : _businessesDao = businessesDao,
       _categoriesDao = categoriesDao,
       _productsDao = productsDao,
       _productVariantsDao = productVariantsDao,
       _businessRemoteDs = businessRemoteDs,
       _productsRemoteDs = productsRemoteDs,
       _connectivityService = connectivityService;

  /// Initialize sync service and listen for connectivity changes.
  /// On each reconnect: push pending local changes, then pull from server.
  void init() {
    // Sync immediately if already online at startup.
    _connectivityService.isConnected.then((online) {
      if (online) syncAll();
    });

    // Also sync whenever connectivity is restored.
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((isConnected) {
          if (isConnected) {
            syncAll();
          }
        });
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Check if we're online
  Future<bool> get isOnline => _connectivityService.isConnected;

  /// Reactive total count of all records pending sync (categories + products + variants).
  /// Emits a new value whenever any local record changes sync status.
  Stream<int> watchTotalPendingSyncCount() {
    int cat = 0, prod = 0, vars = 0;
    final controller = StreamController<int>.broadcast();

    void emit() {
      if (!controller.isClosed) controller.add(cat + prod + vars);
    }

    final s1 = _categoriesDao.watchPendingSyncCount().listen((n) { cat = n; emit(); });
    final s2 = _productsDao.watchPendingSyncCount().listen((n) { prod = n; emit(); });
    final s3 = _productVariantsDao.watchPendingSyncCount().listen((n) { vars = n; emit(); });

    controller.onCancel = () {
      s1.cancel();
      s2.cancel();
      s3.cancel();
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
      // ── Upload phase ────────────────────────────────────────────────────────
      final businessResult = await _syncBusinesses();
      final categoryResult = await _syncCategories();
      final productResult = await _syncProducts();
      final variantResult = await _syncProductVariants();

      final int totalSynced = businessResult.syncedCount +
          categoryResult.syncedCount +
          productResult.syncedCount +
          variantResult.syncedCount;
      final int totalFailed = businessResult.failedCount +
          categoryResult.failedCount +
          productResult.failedCount +
          variantResult.failedCount;

      // ── Pull phase (only if businessId is known) ────────────────────────────
      SyncResult pullResult = SyncResult(
        success: true,
        message: 'Pull skipped (no businessId)',
      );
      if (businessId != null) {
        pullResult = await pullFromServer(businessId);
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

  // ── UPLOAD: categories ─────────────────────────────────────────────────────

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

  // ── UPLOAD: products ───────────────────────────────────────────────────────

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

  // ── UPLOAD: product variants ───────────────────────────────────────────────

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

  // ── UPLOAD: businesses ─────────────────────────────────────────────────────

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

  // ── PULL: download from Supabase → local ───────────────────────────────────

  /// Pull all categories, products, and variants for [businessId] from Supabase
  /// and upsert them locally. Only runs when online.
  /// Records pulled from server are marked syncStatus=synced (3).
  Future<SyncResult> pullFromServer(String businessId) async {
    final online = await isOnline;
    if (!online) {
      return SyncResult(success: false, message: 'Pull skipped: offline');
    }

    int pulled = 0;
    int failed = 0;
    final errors = <String>[];

    // Pull categories
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

    // Pull products
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

    // Pull variants
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
