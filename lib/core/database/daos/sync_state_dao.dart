import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/sync_state_table.dart';

part 'sync_state_dao.g.dart';

/// Read/write access to the per-entity delta-sync watermark.
/// See docs/delta_sync_design.md. Consumed by SyncService's
/// _pullIncremental for the (timestamp, id) keyset cursor.
@DriftAccessor(tables: [SyncStateTable])
class SyncStateDao extends DatabaseAccessor<AppDatabase>
    with _$SyncStateDaoMixin {
  SyncStateDao(super.db);

  /// The (timestamp, id) keyset cursor of the last row pulled for
  /// [entity]/[businessId]. Both null means never delta-pulled (full pull).
  /// `id` may be null for cursors written before the tiebreak column existed.
  Future<({DateTime? ts, String? id})> getWatermark(
    String entity,
    String businessId,
  ) async {
    final row = await (select(syncStateTable)
          ..where(
            (t) => t.entity.equals(entity) & t.businessId.equals(businessId),
          ))
        .getSingleOrNull();
    return (ts: row?.lastPulledAt, id: row?.lastPulledId);
  }

  /// Advance the cursor after a page has been fully applied.
  Future<void> setWatermark(
    String entity,
    String businessId,
    DateTime ts,
    String id,
  ) {
    return into(syncStateTable).insertOnConflictUpdate(
      SyncStateTableCompanion.insert(
        entity: entity,
        businessId: businessId,
        lastPulledAt: Value(ts),
        lastPulledId: Value(id),
      ),
    );
  }

  /// Drop all watermarks so the next sync does a fresh full pull
  /// (call from logout / clearLocalData).
  Future<void> clearAll() => delete(syncStateTable).go();
}
