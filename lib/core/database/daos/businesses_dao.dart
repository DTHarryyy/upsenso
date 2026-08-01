import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/businesses_table.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/business/domain/entities/business.dart';

part 'businesses_dao.g.dart';

@DriftAccessor(tables: [BusinessesTable])
class BusinessesDao extends DatabaseAccessor<AppDatabase>
    with _$BusinessesDaoMixin {
  BusinessesDao(super.db);

  /// Get all businesses
  Future<List<BusinessesTableData>> getAll() {
    return select(businessesTable).get();
  }

  /// Watch all businesses (for reactive UI)
  Stream<List<BusinessesTableData>> watchAll() {
    return select(businessesTable).watch();
  }

  /// Get business by ID
  Future<BusinessesTableData?> getById(String id) {
    return (select(
      businessesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get business by owner ID
  Future<BusinessesTableData?> getByOwnerId(String ownerId) {
    return (select(
      businessesTable,
    )..where((t) => t.ownerId.equals(ownerId))).getSingleOrNull();
  }

  /// Watch business by owner ID
  Stream<BusinessesTableData?> watchByOwnerId(String ownerId) {
    return (select(
      businessesTable,
    )..where((t) => t.ownerId.equals(ownerId))).watchSingleOrNull();
  }

  /// Insert a new business (locally created, pending upload)
  /// Insert the local business row. Idempotent by id: signup retries reuse the
  /// same id on purpose (a fresh one per attempt is what orphaned 8 businesses
  /// on 2026-07-26), so a second attempt must overwrite rather than collide.
  Future<void> insertBusiness(Business business) async {
    await into(businessesTable).insertOnConflictUpdate(
      BusinessesTableCompanion.insert(
        id: business.id,
        name: business.name,
        ownerId: business.ownerId,
        templateId: business.templateId,
        createdAt: business.createdAt,
        isActive: Value(business.isActive),
        syncStatus: const Value(0), // pendingUpload
      ),
    );
  }

  /// Insert or replace a business (from server sync)
  Future<void> upsertFromServer(Business business) async {
    await into(businessesTable).insert(
      BusinessesTableCompanion.insert(
        id: business.id,
        name: business.name,
        ownerId: business.ownerId,
        templateId: business.templateId,
        createdAt: business.createdAt,
        isActive: Value(business.isActive),
        syncStatus: const Value(3), // synced
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Update business locally (marks as pending update)
  Future<void> updateBusiness(Business business) async {
    await (update(
      businessesTable,
    )..where((t) => t.id.equals(business.id))).write(
      BusinessesTableCompanion(
        name: Value(business.name),
        isActive: Value(business.isActive),
        syncStatus: const Value(1), // pendingUpdate
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Mark business for deletion (soft delete pending sync)
  Future<void> markForDeletion(String id) async {
    await (update(businessesTable)..where((t) => t.id.equals(id))).write(
      BusinessesTableCompanion(
        syncStatus: const Value(2), // pendingDelete
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get all records that need syncing
  Future<List<BusinessesTableData>> getPendingSync() {
    return (select(
      businessesTable,
    )..where((t) => t.syncStatus.isIn([0, 1, 2, 4]))).get();
  }

  /// Watch pending sync count
  Stream<int> watchPendingSyncCount() {
    final countExp = businessesTable.id.count();
    final query = selectOnly(businessesTable)
      ..addColumns([countExp])
      ..where(businessesTable.syncStatus.isIn([0, 1, 2, 4]));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  /// Update sync status after sync attempt
  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) async {
    await (update(businessesTable)..where((t) => t.id.equals(id))).write(
      BusinessesTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// Delete a synced record (after successful server deletion)
  Future<void> hardDelete(String id) async {
    await (delete(businessesTable)..where((t) => t.id.equals(id))).go();
  }

  /// Clear all businesses (for logout/reset)
  Future<void> clearAll() {
    return delete(businessesTable).go();
  }

  /// Convert table data to domain entity
  static Business toEntity(BusinessesTableData data) {
    return Business(
      id: data.id,
      name: data.name,
      ownerId: data.ownerId,
      templateId: data.templateId,
      createdAt: data.createdAt,
      isActive: data.isActive,
    );
  }

  /// Get sync status for a record
  static SyncStatus getSyncStatus(BusinessesTableData data) {
    return SyncStatusExtension.fromInt(data.syncStatus);
  }
}
