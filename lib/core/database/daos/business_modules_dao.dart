import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/business_modules_table.dart';

part 'business_modules_dao.g.dart';

@DriftAccessor(tables: [BusinessModulesTable])
class BusinessModulesDao extends DatabaseAccessor<AppDatabase>
    with _$BusinessModulesDaoMixin {
  BusinessModulesDao(super.db);

  /// Returns the set of enabled module codes for [businessId].
  ///
  /// An empty set means no modules are cached yet — callers should treat all
  /// modules as enabled until the first sync completes.
  Future<Set<String>> getEnabledModuleCodes(String businessId) async {
    final rows = await (select(businessModulesTable)
          ..where(
            (t) => t.businessId.equals(businessId) & t.enabled.equals(true),
          ))
        .get();
    return rows.map((r) => r.moduleCode).toSet();
  }

  /// Returns all cached module rows for [businessId] (enabled and disabled).
  Future<List<BusinessModuleRow>> getAll(String businessId) async {
    return (select(businessModulesTable)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
  }

  /// Replaces the cached module list for [businessId] atomically.
  ///
  /// [modules] is a map of moduleCode → enabled.
  Future<void> saveModules(
    String businessId,
    Map<String, bool> modules,
  ) async {
    final now = DateTime.now();
    await batch((b) {
      for (final entry in modules.entries) {
        b.insert(
          businessModulesTable,
          BusinessModulesTableCompanion(
            businessId: Value(businessId),
            moduleCode: Value(entry.key),
            enabled: Value(entry.value),
            syncedAt: Value(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Removes all cached module rows for [businessId].  Call on sign-out.
  Future<void> clearForBusiness(String businessId) async {
    await (delete(businessModulesTable)
          ..where((t) => t.businessId.equals(businessId)))
        .go();
  }
}
