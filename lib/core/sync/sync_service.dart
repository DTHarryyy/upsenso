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

  /// Initialize sync service and listen for connectivity changes
  void init() {
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

  /// Sync all pending records
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    final online = await isOnline;
    if (!online) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    _isSyncing = true;

    try {
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

      return SyncResult(
        success: businessResult.success &&
            categoryResult.success &&
            productResult.success &&
            variantResult.success,
        message:
            '${businessResult.message}; ${categoryResult.message}; ${productResult.message}; ${variantResult.message}',
        syncedCount: totalSynced,
        failedCount: totalFailed,
        errors: [
          ...businessResult.errors,
          ...categoryResult.errors,
          ...productResult.errors,
          ...variantResult.errors,
        ],
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync pending category records to Supabase
  Future<SyncResult> _syncCategories() async {
    final pending = await _categoriesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      try {
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

  /// Sync pending product records to Supabase
  Future<SyncResult> _syncProducts() async {
    final pending = await _productsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      try {
        await _productsRemoteDs.createProduct(
          id: record.id,
          businessId: record.businessId,
          categoryId: record.categoryId,
          name: record.name,
          sku: record.sku,
          barcode: record.barcode,
          hasVariants: record.hasVariants,
          isActive: record.isActive,
        );
        await _productsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.synced,
        );
        synced++;
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

  /// Sync pending product variant records to Supabase
  Future<SyncResult> _syncProductVariants() async {
    final pending = await _productVariantsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      try {
        await _productsRemoteDs.createProductVariant(
          id: record.id,
          productId: record.productId,
          businessId: record.businessId,
          name: record.name,
          price: record.price,
          costPrice: record.costPrice,
          stock: record.stock,
          sku: record.sku,
          barcode: record.barcode,
          isActive: record.isActive,
        );
        await _productVariantsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.synced,
        );
        synced++;
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

  /// Sync business records
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
            await _handlePendingUpload(record);
            synced++;
            break;

          case SyncStatus.pendingUpdate:
            await _handlePendingUpdate(record);
            synced++;
            break;

          case SyncStatus.pendingDelete:
            await _handlePendingDelete(record);
            synced++;
            break;

          case SyncStatus.failed:
            await _handlePendingUpload(record);
            synced++;
            break;

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
      message: 'Synced $synced, Failed $failed',
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

  /// Pull latest data from server and update local DB
  Future<void> pullFromServer(String ownerId) async {
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
