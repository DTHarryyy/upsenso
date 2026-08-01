import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/entitlement_cache_table.dart';
import 'package:pos/core/database/tables/entitlement_locks_table.dart';
import 'package:pos/core/database/tables/resource_usage_cache_table.dart';

part 'entitlement_dao.g.dart';

/// Read/write access to the local entitlement + usage caches and the over-cap
/// lock set.
///
/// Only the entitlement sync path writes here; feature code reads through
/// EntitlementService / EntitlementEnforcementService, never this DAO directly.
@DriftAccessor(
  tables: [
    EntitlementCacheTable,
    ResourceUsageCacheTable,
    EntitlementLocksTable,
  ],
)
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

  // ── Over-cap locks ────────────────────────────────────────────────────────

  Future<List<EntitlementLockRow>> getLocks(
    String businessId,
    String resourceKind,
  ) {
    return (select(entitlementLocksTable)..where(
          (t) =>
              t.businessId.equals(businessId) &
              t.resourceKind.equals(resourceKind),
        ))
        .get();
  }

  /// Replace the lock set for one resource kind in a single transaction, so a
  /// reconcile can never leave a half-applied set behind if it's interrupted.
  Future<void> replaceLocks({
    required String businessId,
    required String resourceKind,
    required Iterable<String> resourceIds,
    required String lockedUnderPlan,
  }) async {
    await transaction(() async {
      await (delete(entitlementLocksTable)..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.resourceKind.equals(resourceKind),
          ))
          .go();
      for (final id in resourceIds) {
        await into(entitlementLocksTable).insertOnConflictUpdate(
          EntitlementLocksTableCompanion.insert(
            businessId: businessId,
            resourceKind: resourceKind,
            resourceId: id,
            lockedUnderPlan: Value(lockedUnderPlan),
          ),
        );
      }
    });
  }

  /// Account-switch / logout hygiene: entitlement is tenant state and must
  /// never leak across businesses on a shared device.
  Future<void> clearAll() async {
    await delete(entitlementCacheTable).go();
    await delete(resourceUsageCacheTable).go();
    await delete(entitlementLocksTable).go();
  }
}
