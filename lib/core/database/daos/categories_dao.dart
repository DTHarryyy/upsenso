import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/categories_table.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/products/domain/entities/category.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Bulk-inserts default categories for a business.
  /// Guards against duplicate seeding: skips if categories already exist.
  Future<void> insertDefaults({
    required String businessId,
    required List<String> categories,
  }) async {
    final existing = await getByBusinessId(businessId);
    if (existing.isNotEmpty) return;

    await batch((b) {
      for (var i = 0; i < categories.length; i++) {
        b.insert(
          categoriesTable,
          CategoriesTableCompanion.insert(
            id: const Uuid().v4(),
            businessId: businessId,
            name: categories[i],
            sortOrder: Value(i),
            syncStatus: const Value(0), // pendingUpload
          ),
        );
      }
    });
  }

  /// Get all categories for a business.
  Future<List<CategoriesTableData>> getByBusinessId(String businessId) {
    return (select(categoriesTable)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Reactive stream of categories for a business (for UI).
  Stream<List<CategoriesTableData>> watchByBusinessId(String businessId) {
    return (select(categoriesTable)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// Reactive count of records that need syncing.
  Stream<int> watchPendingSyncCount() {
    final countExp = categoriesTable.id.count();
    final query = selectOnly(categoriesTable)
      ..addColumns([countExp])
      ..where(categoriesTable.syncStatus.isIn([0, 1, 2, 4]));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  /// Records pending upload, update, delete, or retry.
  Future<List<CategoriesTableData>> getPendingSync() {
    return (select(categoriesTable)
          ..where((t) => t.syncStatus.isIn([0, 1, 2, 4])))
        .get();
  }

  /// Update sync status after a sync attempt.
  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) async {
    await (update(categoriesTable)..where((t) => t.id.equals(id))).write(
      CategoriesTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// Hard-delete a category (after successful server deletion).
  Future<void> hardDelete(String id) {
    return (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
  }

  /// Insert a single category (e.g., added inline from the Add Product page).
  /// Returns the new category's id.
  Future<String> insertSingle({
    required String businessId,
    required String name,
  }) async {
    final existing = await getByBusinessId(businessId);
    final nextOrder = existing.length;
    final id = const Uuid().v4();
    await into(categoriesTable).insert(
      CategoriesTableCompanion.insert(
        id: id,
        businessId: businessId,
        name: name,
        sortOrder: Value(nextOrder),
        syncStatus: const Value(0), // pendingUpload
      ),
    );
    return id;
  }

  /// Upsert a category row pulled from Supabase (marks as synced).
  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(categoriesTable).insertOnConflictUpdate(
      CategoriesTableCompanion.insert(
        id: row['id'] as String,
        businessId: row['business_id'] as String,
        name: row['name'] as String,
        sortOrder: Value((row['sort_order'] as int?) ?? 0),
        syncStatus: const Value(3), // synced
        lastSyncAttempt: Value(DateTime.now()),
      ),
    );
  }

  /// Clear all categories (e.g., on logout/reset).
  Future<void> clearAll() {
    return delete(categoriesTable).go();
  }

  /// Convert a Drift row to the domain entity.
  static Category toEntity(CategoriesTableData data) {
    return Category(
      id: data.id,
      businessId: data.businessId,
      name: data.name,
      sortOrder: data.sortOrder,
    );
  }
}
