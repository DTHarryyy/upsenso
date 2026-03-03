import 'package:uuid/uuid.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/models/business_model.dart';
import 'package:pos/features/business/data/models/business_template_model.dart';
import 'package:pos/features/business/domain/entities/business.dart';
import 'package:pos/features/business/domain/entities/business_template.dart';
import 'package:pos/features/business/domain/repositories/business_repository.dart';

/// Offline-first implementation of BusinessRepository
///
/// Pattern:
/// 1. Save data locally to Drift first
/// 2. Mark record with sync status (pendingUpload, pendingUpdate, etc.)
/// 3. Attempt to sync to Supabase if online
/// 4. Return local data immediately for fast UI response
class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDs remote;
  final BusinessesDao businessesDao;
  final BusinessTemplatesDao templatesDao;
  final ConnectivityService connectivity;

  BusinessRepositoryImpl({
    required this.remote,
    required this.businessesDao,
    required this.templatesDao,
    required this.connectivity,
  });

  @override
  Future<List<BusinessTemplate>> getBusinessTemplates() async {
    // Try to get from local cache first
    final localTemplates = await templatesDao.getAllTemplates();

    if (localTemplates.isNotEmpty) {
      // Return cached data immediately
      final templates = localTemplates
          .map((t) => BusinessTemplatesDao.toEntity(t))
          .toList();

      // Refresh from server in background if online
      _refreshTemplatesFromServer();

      return templates;
    }

    // No local data, must fetch from server
    final online = await connectivity.isConnected;
    if (!online) {
      return []; // No local data and offline
    }

    // Fetch from server and cache locally
    final data = await remote.getBusinessTemplates();
    final templates = data
        .map((json) => BusinessTemplateModel.fromJson(json))
        .toList();

    // Cache locally
    await templatesDao.upsertTemplates(templates);

    return templates;
  }

  Future<void> _refreshTemplatesFromServer() async {
    try {
      final online = await connectivity.isConnected;
      if (!online) return;

      final data = await remote.getBusinessTemplates();
      final templates = data
          .map((json) => BusinessTemplateModel.fromJson(json))
          .toList();

      await templatesDao.upsertTemplates(templates);
    } catch (_) {
      // Silent fail for background refresh
    }
  }

  @override
  Future<Business> createBusiness({
    required String name,
    required String ownerId,
    required String templateId,
  }) async {
    // 1. Generate UUID locally
    final id = const Uuid().v4();
    final now = DateTime.now();

    // 2. Create business entity
    final business = Business(
      id: id,
      name: name,
      ownerId: ownerId,
      templateId: templateId,
      createdAt: now,
      isActive: true,
    );

    // 3. Save locally FIRST (offline-first)
    await businessesDao.insertBusiness(business);

    // 4. Try to sync to server if online
    final online = await connectivity.isConnected;
    if (online) {
      try {
        // Upload to Supabase
        final serverData = await remote.createBusiness(
          name: name,
          ownerId: ownerId,
          templateId: templateId,
        );

        // Update local record with server response and mark as synced
        final serverBusiness = BusinessModel.fromJson(serverData);

        // If server generated different ID, update local record
        if (serverBusiness.id != id) {
          await businessesDao.hardDelete(id);
          await businessesDao.upsertFromServer(serverBusiness);
          return serverBusiness;
        }

        // Mark as synced
        await businessesDao.updateSyncStatus(id: id, status: SyncStatus.synced);

        return serverBusiness;
      } catch (e) {
        // Sync failed, but local data is saved
        // Will retry on next sync cycle
        await businessesDao.updateSyncStatus(
          id: id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    // Return local business (may be pending sync)
    return business;
  }

  @override
  Future<Business?> getBusinessByOwner(String ownerId) async {
    // 1. Check local cache first
    final localBusiness = await businessesDao.getByOwnerId(ownerId);

    if (localBusiness != null) {
      // Return cached data immediately
      final business = BusinessesDao.toEntity(localBusiness);

      // Refresh from server in background if online and synced
      final status = BusinessesDao.getSyncStatus(localBusiness);
      if (status == SyncStatus.synced) {
        _refreshBusinessFromServer(ownerId);
      }

      return business;
    }

    // 2. No local data, try server
    final online = await connectivity.isConnected;
    if (!online) {
      return null; // No local data and offline
    }

    final data = await remote.getBusinessByOwner(ownerId);
    if (data == null) return null;

    // Cache locally
    final business = BusinessModel.fromJson(data);
    await businessesDao.upsertFromServer(business);

    return business;
  }

  Future<void> _refreshBusinessFromServer(String ownerId) async {
    try {
      final online = await connectivity.isConnected;
      if (!online) return;

      final data = await remote.getBusinessByOwner(ownerId);
      if (data != null) {
        final business = BusinessModel.fromJson(data);
        await businessesDao.upsertFromServer(business);
      }
    } catch (_) {
      // Silent fail for background refresh
    }
  }

  @override
  Future<Business?> getBusinessById(String businessId) async {
    // 1. Check local cache first
    final localBusiness = await businessesDao.getById(businessId);

    if (localBusiness != null) {
      return BusinessesDao.toEntity(localBusiness);
    }

    // 2. No local data, try server
    final online = await connectivity.isConnected;
    if (!online) {
      return null;
    }

    final data = await remote.getBusinessById(businessId);
    if (data == null) return null;

    // Cache locally
    final business = BusinessModel.fromJson(data);
    await businessesDao.upsertFromServer(business);

    return business;
  }

  /// Watch pending sync count for UI indicator
  Stream<int> watchPendingSyncCount() {
    return businessesDao.watchPendingSyncCount();
  }

  /// Watch business by owner for reactive UI
  Stream<Business?> watchBusinessByOwner(String ownerId) {
    return businessesDao.watchByOwnerId(ownerId).map((data) {
      return data != null ? BusinessesDao.toEntity(data) : null;
    });
  }
}
