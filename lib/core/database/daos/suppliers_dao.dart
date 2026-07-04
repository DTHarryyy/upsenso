import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/suppliers_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'suppliers_dao.g.dart';

@DriftAccessor(tables: [SuppliersTable])
class SuppliersDao extends DatabaseAccessor<AppDatabase>
    with _$SuppliersDaoMixin {
  SuppliersDao(super.db);

  Stream<List<SupplierRow>> watchActiveByBusinessId(String businessId) {
    return (select(suppliersTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.isDeleted.equals(false) &
                t.syncStatus.isNotIn([SyncStatus.pendingDelete.toInt()]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<SupplierRow>> getActiveByBusinessId(String businessId) {
    return (select(suppliersTable)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.isDeleted.equals(false) &
                t.syncStatus.isNotIn([SyncStatus.pendingDelete.toInt()]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<SupplierRow?> getById(String id) {
    return (select(suppliersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insert(SuppliersTableCompanion companion) {
    return into(suppliersTable).insert(companion);
  }

  Future<void> updateSupplier(String id, SuppliersTableCompanion companion) {
    return (update(suppliersTable)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// Soft delete — marks the row; sync will propagate the soft-delete flag to
  /// Supabase. Never hard-delete; suppliers may be referenced by historical POs.
  Future<void> softDelete(String id) async {
    final row = await getById(id);
    if (row == null) return;
    await (update(suppliersTable)..where((t) => t.id.equals(id))).write(
      SuppliersTableCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
        syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearAll() {
    return delete(suppliersTable).go();
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = suppliersTable.id.count();
    final query = selectOnly(suppliersTable)
      ..addColumns([countExp])
      ..where(
        suppliersTable.syncStatus.isIn([
          SyncStatus.pendingUpload.toInt(),
          SyncStatus.pendingUpdate.toInt(),
          SyncStatus.pendingDelete.toInt(),
          SyncStatus.failed.toInt(),
        ]),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<SupplierRow>> getPendingSync() {
    return (select(suppliersTable)
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
    return (update(suppliersTable)..where((t) => t.id.equals(id))).write(
      SuppliersTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    // Never overwrite a local row that still has unsynced changes — a failed
    // push followed by a pull would otherwise silently discard the offline edit.
    final existing = await getById(id);
    if (existing != null && existing.syncStatus != SyncStatus.synced.toInt()) {
      return;
    }
    await into(suppliersTable).insertOnConflictUpdate(
      SuppliersTableCompanion.insert(
        id: id,
        businessId: row['business_id'] as String,
        name: row['name'] as String,
        contactName: Value(row['contact_name'] as String?),
        phone: Value(row['phone'] as String?),
        email: Value(row['email'] as String?),
        address: Value(row['address'] as String?),
        taxId: Value(row['tax_id'] as String?),
        notes: Value(row['notes'] as String?),
        isActive: Value((row['is_active'] as bool?) ?? true),
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

  Future<void> hardDelete(String id) {
    return (delete(suppliersTable)..where((t) => t.id.equals(id))).go();
  }
}
