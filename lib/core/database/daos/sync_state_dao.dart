import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/sync_state_table.dart';

part 'sync_state_dao.g.dart';

/// Read/write access to the per-entity delta-sync watermark.
/// See docs/delta_sync_design.md. Not yet consumed by SyncService.
@DriftAccessor(tables: [SyncStateTable])
class SyncStateDao extends DatabaseAccessor<AppDatabase>
    with _$SyncStateDaoMixin {
  SyncStateDao(super.db);

  /// Server `updated_at` of the last row pulled for [entity]/[businessId], or
  /// null if it has never been delta-pulled (caller should do a full pull).
  Future<DateTime?> getWatermark(String entity, String businessId) async {
    final row = await (select(syncStateTable)
          ..where(
            (t) => t.entity.equals(entity) & t.businessId.equals(businessId),
          ))
        .getSingleOrNull();
    return row?.lastPulledAt;
  }

  /// Advance the watermark after a page has been fully applied.
  Future<void> setWatermark(String entity, String businessId, DateTime ts) {
    return into(syncStateTable).insertOnConflictUpdate(
      SyncStateTableCompanion.insert(
        entity: entity,
        businessId: businessId,
        lastPulledAt: Value(ts),
      ),
    );
  }

  /// Drop all watermarks so the next sync does a fresh full pull
  /// (call from logout / clearLocalData).
  Future<void> clearAll() => delete(syncStateTable).go();
}
