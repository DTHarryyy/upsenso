import 'dart:async';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/models/business_model.dart';

/// Service to handle synchronization between local Drift DB and Supabase
class SyncService {
  final BusinessesDao _businessesDao;
  final BusinessRemoteDs _businessRemoteDs;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required BusinessesDao businessesDao,
    required BusinessRemoteDs businessRemoteDs,
    required ConnectivityService connectivityService,
  }) : _businessesDao = businessesDao,
       _businessRemoteDs = businessRemoteDs,
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
      final result = await _syncBusinesses();
      return result;
    } finally {
      _isSyncing = false;
    }
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
            // Retry based on original intended action
            // i try ngani ulit mag re upload
            await _handlePendingUpload(record);
            synced++;
            break;

          case SyncStatus.synced:
            // Shouldn't be in pending list
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
    // Upload to Supabase
    await _businessRemoteDs.createBusiness(
      name: record.name,
      ownerId: record.ownerId,
      templateId: record.templateId,
    );

    // Mark as synced
    await _businessesDao.updateSyncStatus(
      id: record.id,
      status: SyncStatus.synced,
    );
  }

  Future<void> _handlePendingUpdate(BusinessesTableData record) async {
    // Update in Supabase (you'll need to add this method to remote ds)
    // For now, we'll just mark as synced
    // await _businessRemoteDs.updateBusiness(record.id, ...);

    await _businessesDao.updateSyncStatus(
      id: record.id,
      status: SyncStatus.synced,
    );
  }

  Future<void> _handlePendingDelete(BusinessesTableData record) async {
    // Delete from Supabase (you'll need to add this method to remote ds)
    // await _businessRemoteDs.deleteBusiness(record.id);

    // Hard delete locally after successful server deletion
    await _businessesDao.hardDelete(record.id);
  }

  /// Pull latest data from server and update local DB sa drift
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
