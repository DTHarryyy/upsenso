import 'package:uuid/uuid.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/seeding/default_business_templates.dart';
import 'package:pos/core/seeding/default_categories.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/models/business_model.dart';
import 'package:pos/features/business/data/models/business_template_model.dart';
import 'package:pos/features/business/domain/entities/business.dart';
import 'package:pos/features/business/domain/entities/branch.dart';
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
  final BranchesDao branchesDao;
  final CategoriesDao categoriesDao;
  final ConnectivityService connectivity;
  final AuthRepository authRepository;

  BusinessRepositoryImpl({
    required this.remote,
    required this.businessesDao,
    required this.templatesDao,
    required this.branchesDao,
    required this.categoriesDao,
    required this.connectivity,
    required this.authRepository,
  });

  @override
  Future<List<BusinessTemplate>> getBusinessTemplates() async {
    // Try to get from local cache first
    // Always prefer fresh server data when online to avoid stale template IDs.
    final online = await connectivity.isConnected;
    if (online) {
      try {
        final data = await remote.getBusinessTemplates();
        final templates = data
            .map((json) => BusinessTemplateModel.fromJson(json))
            .toList();

        if (templates.isEmpty) {
          // Migration not yet applied — server has no templates.
          // Fall through to local cache / hardcoded fallback below.
          throw StateError('Server returned empty templates');
        }

        // Replace local cache with server data
        await templatesDao.clearAll();
        await templatesDao.upsertTemplates(templates);

        return templates;
      } catch (_) {
        // Server fetch failed – fall through to local cache
      }
    }

    // Offline or server error – use local cache
    final localTemplates = await templatesDao.getAllTemplates();
    if (localTemplates.isNotEmpty) {
      return localTemplates
          .map((t) => BusinessTemplatesDao.toEntity(t))
          .toList();
    }

    // No cache at all – return hardcoded fallback
    return DefaultBusinessTemplates.all;
  }

  @override
  Future<Business> createBusiness({
    required String name,
    required String ownerId,
    required String templateId,
    required String branchName,
  }) async {
    // 1. Generate UUIDs locally
    final businessId = const Uuid().v4();
    final branchId = const Uuid().v4();
    final now = DateTime.now();

    // 2. Create business entity
    final business = Business(
      id: businessId,
      name: name,
      ownerId: ownerId,
      templateId: templateId,
      createdAt: now,
      isActive: true,
    );

    // 3. Create initial branch entity
    final branch = Branch(
      id: branchId,
      businessId: businessId,
      name: branchName,
    );

    // 4. Save locally FIRST (offline-first)
    await businessesDao.insertBusiness(business);
    await branchesDao.insertBranch(branch);

    // 5. Seed default categories locally (offline-first fallback)
    await categoriesDao.insertDefaults(
      businessId: businessId,
      categories: DefaultCategories.forTemplateId(templateId),
    );

    // 6. Try to sync to server if online
    final online = await connectivity.isConnected;
    if (online) {
      try {
        // Upload business to Supabase
        final serverData = await remote.createBusiness(
          id: businessId,
          name: name,
          ownerId: ownerId,
          templateId: templateId,
        );

        // Upload branch to Supabase
        await remote.createBranch(
          id: branchId,
          businessId: businessId,
          name: branchName,
        );

        // Apply template server-side: creates all 4 roles, seeds server categories,
        // and initialises receipt_settings in one atomic RPC call.
        // Returns the Super Admin role UUID so we can link the owner.
        final superAdminRoleId = await remote.applyBusinessTemplate(
          businessId: businessId,
          templateId: templateId,
        );
        final currentUser = authRepository.getCurrentUser();
        await remote.createUserForBusiness(
          businessId: businessId,
          userId: ownerId,
          email: currentUser?.email ?? '',
          fullName: currentUser?.fullName,
          superAdminRoleId: superAdminRoleId,
        );

        // Update local business record with server response and mark as synced
        final serverBusiness = BusinessModel.fromJson(serverData);

        // Keep local cache aligned with server payload.
        await businessesDao.upsertFromServer(serverBusiness);

        // Mark business as synced
        await businessesDao.updateSyncStatus(
          id: serverBusiness.id,
          status: SyncStatus.synced,
        );

        // Mark branch as synced
        await branchesDao.updateSyncStatus(
          id: branchId,
          status: SyncStatus.synced,
        );

        return serverBusiness;
      } catch (e) {
        // Sync failed, but local data is saved
        // Will retry on next sync cycle
        await businessesDao.updateSyncStatus(
          id: businessId,
          status: SyncStatus.failed,
          error: e.toString(),
        );

        // When online, treat create failure as an error to avoid routing
        // into screens that require server-side business/user context.
        throw Exception('Failed to create business on server: $e');
      }
    }

    // Return local business (may be pending sync)
    return business;
  }

  @override
  Future<Business?> getBusinessByOwner(String ownerId) async {
    final online = await connectivity.isConnected;

    if (online) {
      // When online, trust server state to avoid routing into screens that
      // require remote context while only local unsynced data exists.
      final data = await remote.getBusinessByOwner(ownerId);
      if (data == null) return null;

      final business = BusinessModel.fromJson(data);
      await businessesDao.upsertFromServer(business);
      return business;
    }

    // Offline fallback: use local cache.
    final localBusiness = await businessesDao.getByOwnerId(ownerId);
    if (localBusiness != null) {
      return BusinessesDao.toEntity(localBusiness);
    }

    return null;
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
