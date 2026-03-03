import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/branches_table.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/business/domain/entities/branch.dart';

part 'branches_dao.g.dart';

@DriftAccessor(tables: [BranchesTable])
class BranchesDao extends DatabaseAccessor<AppDatabase>
    with _$BranchesDaoMixin {
  BranchesDao(super.db);

  /// Get all branches
  Future<List<BranchesTableData>> getAll() {
    return select(branchesTable).get();
  }

  /// Watch all branches (for reactive UI)
  Stream<List<BranchesTableData>> watchAll() {
    return select(branchesTable).watch();
  }

  /// Get branch by ID
  Future<BranchesTableData?> getById(String id) {
    return (select(
      branchesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get branches by business ID
  Future<List<BranchesTableData>> getByBusinessId(String businessId) {
    return (select(
      branchesTable,
    )..where((t) => t.businessId.equals(businessId))).get();
  }

  /// Watch branches by business ID
  Stream<List<BranchesTableData>> watchByBusinessId(String businessId) {
    return (select(
      branchesTable,
    )..where((t) => t.businessId.equals(businessId))).watch();
  }

  /// Insert a new branch (locally created, pending upload)
  Future<void> insertBranch(Branch branch) async {
    await into(branchesTable).insert(
      BranchesTableCompanion.insert(
        id: branch.id,
        businessId: branch.businessId,
        name: branch.name,
        address: Value(branch.address),
        phone: Value(branch.phone),
        isActive: Value(branch.isActive),
        syncStatus: const Value(0), // pendingUpload
      ),
    );
  }

  /// Insert or replace a branch (from server sync)
  Future<void> upsertFromServer(Branch branch) async {
    await into(branchesTable).insert(
      BranchesTableCompanion.insert(
        id: branch.id,
        businessId: branch.businessId,
        name: branch.name,
        address: Value(branch.address),
        phone: Value(branch.phone),
        isActive: Value(branch.isActive),
        syncStatus: const Value(3), // synced
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Update branch locally (marks as pending update)
  Future<void> updateBranch(Branch branch) async {
    await (update(branchesTable)..where((t) => t.id.equals(branch.id))).write(
      BranchesTableCompanion(
        name: Value(branch.name),
        address: Value(branch.address),
        phone: Value(branch.phone),
        isActive: Value(branch.isActive),
        syncStatus: const Value(1), // pendingUpdate
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Mark branch for deletion (soft delete pending sync)
  Future<void> markForDeletion(String id) async {
    await (update(branchesTable)..where((t) => t.id.equals(id))).write(
      BranchesTableCompanion(
        syncStatus: const Value(2), // pendingDelete
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get all records that need syncing
  Future<List<BranchesTableData>> getPendingSync() {
    return (select(branchesTable)
          ..where((t) => t.syncStatus.isIn([0, 1, 2]))) // pending states
        .get();
  }

  /// Update sync status
  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) async {
    await (update(branchesTable)..where((t) => t.id.equals(id))).write(
      BranchesTableCompanion(
        syncStatus: Value(status.index),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// Hard delete (after successful server delete)
  Future<void> hardDelete(String id) async {
    await (delete(branchesTable)..where((t) => t.id.equals(id))).go();
  }

  /// Convert table data to entity
  static Branch toEntity(BranchesTableData data) {
    return Branch(
      id: data.id,
      businessId: data.businessId,
      name: data.name,
      address: data.address,
      phone: data.phone,
      isActive: data.isActive,
    );
  }
}
