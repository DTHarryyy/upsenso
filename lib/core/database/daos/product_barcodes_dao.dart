import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/product_barcodes_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'product_barcodes_dao.g.dart';

@DriftAccessor(tables: [ProductBarcodesTable])
class ProductBarcodesDao extends DatabaseAccessor<AppDatabase>
    with _$ProductBarcodesDaoMixin {
  ProductBarcodesDao(super.db);

  /// Active barcode rows for a variant, primary first.
  Future<List<ProductBarcodeRow>> getByVariantId(String variantId) {
    return (select(productBarcodesTable)
          ..where(
            (t) => t.variantId.equals(variantId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.isPrimary)]))
        .get();
  }

  Future<List<ProductBarcodeRow>> getByBusinessId(String businessId) {
    return (select(productBarcodesTable)..where(
          (t) => t.businessId.equals(businessId) & t.isDeleted.equals(false),
        ))
        .get();
  }

  /// Resolve a scanned code to its (active) barcode row within a business.
  Future<ProductBarcodeRow?> getByCode(String code, String businessId) async {
    final rows =
        await (select(productBarcodesTable)
              ..where(
                (t) =>
                    t.code.equals(code) &
                    t.businessId.equals(businessId) &
                    t.isDeleted.equals(false),
              )
              ..limit(1))
            .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// True if [code] is already used by another (active) barcode in the business.
  /// [excludeVariantId] skips the variant currently being edited so its own
  /// codes don't count as collisions.
  Future<bool> codeExists(
    String code,
    String businessId, {
    String? excludeVariantId,
  }) async {
    final rows =
        await (select(productBarcodesTable)
              ..where((t) {
                var cond =
                    t.code.equals(code) &
                    t.businessId.equals(businessId) &
                    t.isDeleted.equals(false);
                if (excludeVariantId != null) {
                  cond = cond & t.variantId.equals(excludeVariantId).not();
                }
                return cond;
              })
              ..limit(1))
            .get();
    return rows.isNotEmpty;
  }

  /// Reconcile a variant's barcode set to exactly [codes] (trimmed, de-duped):
  /// keep unchanged rows, soft-delete removed ones (pendingDelete), insert new
  /// ones (pendingUpload), and keep the primary flag on the first code. Mirrors
  /// [RecipeLinesDao.replaceForVariant] but preserves synced rows so removals
  /// propagate instead of re-uploading the whole set.
  Future<void> replaceForVariant(
    String variantId,
    String businessId,
    List<String> codes,
  ) async {
    final seen = <String>{};
    final desired = <String>[];
    for (final c in codes) {
      final t = c.trim();
      if (t.isNotEmpty && seen.add(t)) desired.add(t);
    }

    await transaction(() async {
      final existing =
          await (select(productBarcodesTable)..where(
                (t) =>
                    t.variantId.equals(variantId) & t.isDeleted.equals(false),
              ))
              .get();
      final existingByCode = {for (final r in existing) r.code: r};

      // Soft-delete codes no longer desired.
      for (final r in existing) {
        if (!desired.contains(r.code)) {
          await (update(productBarcodesTable)
                ..where((t) => t.id.equals(r.id)))
              .write(
                ProductBarcodesTableCompanion(
                  isDeleted: const Value(true),
                  deletedAt: Value(DateTime.now()),
                  syncStatus: Value(SyncStatus.pendingDelete.toInt()),
                  localUpdatedAt: Value(DateTime.now()),
                ),
              );
        }
      }

      // Insert new codes; fix the primary flag where it changed.
      for (var i = 0; i < desired.length; i++) {
        final code = desired[i];
        final isPrimary = i == 0;
        final row = existingByCode[code];
        if (row == null) {
          await into(productBarcodesTable).insert(
            ProductBarcodesTableCompanion.insert(
              id: const Uuid().v4(),
              businessId: businessId,
              variantId: variantId,
              code: code,
              isPrimary: Value(isPrimary),
              syncStatus: Value(SyncStatus.pendingUpload.toInt()),
            ),
          );
        } else if (row.isPrimary != isPrimary) {
          await (update(productBarcodesTable)
                ..where((t) => t.id.equals(row.id)))
              .write(
                ProductBarcodesTableCompanion(
                  isPrimary: Value(isPrimary),
                  syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
                  localUpdatedAt: Value(DateTime.now()),
                ),
              );
        }
      }
    });
  }

  /// Insert a single barcode row (used by the local backfill on upgrade).
  Future<void> insertRow(ProductBarcodesTableCompanion row) {
    return into(productBarcodesTable).insert(row);
  }

  Future<void> markDeleteByVariantId(String variantId) {
    return (update(productBarcodesTable)
          ..where((t) => t.variantId.equals(variantId)))
        .write(
          ProductBarcodesTableCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(DateTime.now()),
            syncStatus: Value(SyncStatus.pendingDelete.toInt()),
            localUpdatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> clearAll() {
    return delete(productBarcodesTable).go();
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = productBarcodesTable.id.count();
    final query = selectOnly(productBarcodesTable)
      ..addColumns([countExp])
      ..where(
        productBarcodesTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.pendingDelete.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<ProductBarcodeRow>> getPendingSync() {
    return (select(productBarcodesTable)..where(
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
    return (update(productBarcodesTable)..where((t) => t.id.equals(id))).write(
      ProductBarcodesTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(productBarcodesTable)..where((t) => t.id.equals(id))).go();
  }

  /// Upsert a barcode pulled from Supabase (marks as synced). Never clobbers a
  /// row with unsynced local edits.
  Future<void> upsertFromServer(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final existing =
        await (select(productBarcodesTable)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    if (existing != null && existing.syncStatus != SyncStatus.synced.toInt()) {
      return;
    }
    await into(productBarcodesTable).insertOnConflictUpdate(
      ProductBarcodesTableCompanion.insert(
        id: id,
        businessId: row['business_id'] as String,
        variantId: row['variant_id'] as String,
        code: row['code'] as String,
        isPrimary: Value((row['is_primary'] as bool?) ?? false),
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
