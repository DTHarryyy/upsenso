import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/recipe_lines_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'recipe_lines_dao.g.dart';

@DriftAccessor(tables: [RecipeLinesTable])
class RecipeLinesDao extends DatabaseAccessor<AppDatabase>
    with _$RecipeLinesDaoMixin {
  RecipeLinesDao(super.db);

  /// Active recipe lines for one sellable variant.
  Future<List<RecipeLineRow>> getByVariantId(String productVariantId) {
    return (select(recipeLinesTable)
          ..where(
            (t) =>
                t.productVariantId.equals(productVariantId) &
                t.isDeleted.equals(false),
          ))
        .get();
  }

  Stream<List<RecipeLineRow>> watchByBusinessId(String businessId) {
    return (select(recipeLinesTable)
          ..where(
            (t) => t.businessId.equals(businessId) & t.isDeleted.equals(false),
          ))
        .watch();
  }

  Future<void> insertLines(List<RecipeLinesTableCompanion> lines) async {
    await batch((b) => b.insertAll(recipeLinesTable, lines));
  }

  /// Soft-delete every line of a variant. Used before re-inserting a recipe on
  /// product edit (variants are deleted+reinserted with new UUIDs).
  Future<void> markDeleteByVariantId(String productVariantId) {
    return (update(recipeLinesTable)
          ..where((t) => t.productVariantId.equals(productVariantId)))
        .write(
          RecipeLinesTableCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(DateTime.now()),
            syncStatus: Value(SyncStatus.pendingDelete.toInt()),
            localUpdatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Replace a variant's recipe in one go: soft-delete the old lines, insert new.
  Future<void> replaceForVariant(
    String productVariantId,
    List<RecipeLinesTableCompanion> lines,
  ) async {
    await transaction(() async {
      await markDeleteByVariantId(productVariantId);
      if (lines.isNotEmpty) await insertLines(lines);
    });
  }

  Future<void> clearAll() {
    return delete(recipeLinesTable).go();
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = recipeLinesTable.id.count();
    final query = selectOnly(recipeLinesTable)
      ..addColumns([countExp])
      ..where(
        recipeLinesTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.pendingDelete.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<RecipeLineRow>> getPendingSync() {
    return (select(recipeLinesTable)
          ..where(
            (t) => t.syncStatus.isIn([
              SyncStatus.pendingUpload.toInt(),
              SyncStatus.pendingUpdate.toInt(),
              SyncStatus.pendingDelete.toInt(),
              SyncStatus.failed.toInt(),
            ]),
          ))
        .get();
  }

  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) {
    return (update(recipeLinesTable)..where((t) => t.id.equals(id))).write(
      RecipeLinesTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// Hard-delete a line (after the server delete is confirmed during sync).
  Future<void> hardDelete(String id) {
    return (delete(recipeLinesTable)..where((t) => t.id.equals(id))).go();
  }

  /// Upsert a recipe line pulled from Supabase (marks as synced).
  Future<void> upsertFromServer(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final existing = await (select(recipeLinesTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (existing != null && existing.syncStatus != SyncStatus.synced.toInt()) {
      return;
    }
    await into(recipeLinesTable).insertOnConflictUpdate(
      RecipeLinesTableCompanion.insert(
        id: id,
        businessId: row['business_id'] as String,
        productVariantId: row['product_variant_id'] as String,
        ingredientVariantId: row['ingredient_variant_id'] as String,
        ingredientName: row['ingredient_name'] as String,
        quantity: Value((row['quantity'] as num?)?.toDouble() ?? 0.0),
        unit: Value(row['unit'] as String?),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        deletedAt: Value(
          row['deleted_at'] != null
              ? DateTime.parse(row['deleted_at'] as String)
              : null,
        ),
        createdAt: Value(
          row['created_at'] != null
              ? DateTime.parse(row['created_at'] as String)
              : DateTime.now(),
        ),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
  }
}
