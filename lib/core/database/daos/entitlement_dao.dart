import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/entitlement_cache_table.dart';
import 'package:pos/core/database/tables/resource_usage_cache_table.dart';

part 'entitlement_dao.g.dart';

/// Read/write access to the local entitlement + usage caches.
///
/// Only the entitlement sync path writes here; feature code reads through
/// EntitlementService, never this DAO directly.
@DriftAccessor(tables: [EntitlementCacheTable, ResourceUsageCacheTable])
class EntitlementDao extends DatabaseAccessor<AppDatabase>
    with _$EntitlementDaoMixin {
  EntitlementDao(super.db);

  Future<EntitlementCacheRow?> getEntitlement(String businessId) {
    return (select(entitlementCacheTable)
          ..where((t) => t.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  Future<void> saveEntitlement(EntitlementCacheTableCompanion row) async {
    await into(entitlementCacheTable).insertOnConflictUpdate(row);
  }

  Future<ResourceUsageCacheRow?> getUsage(String businessId) {
    return (select(resourceUsageCacheTable)
          ..where((t) => t.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  Future<void> saveUsage(ResourceUsageCacheTableCompanion row) async {
    await into(resourceUsageCacheTable).insertOnConflictUpdate(row);
  }

  /// Account-switch / logout hygiene: entitlement is tenant state and must
  /// never leak across businesses on a shared device.
  Future<void> clearAll() async {
    await delete(entitlementCacheTable).go();
    await delete(resourceUsageCacheTable).go();
  }
}
