import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/devices_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'devices_dao.g.dart';

@DriftAccessor(tables: [DevicesTable])
class DevicesDao extends DatabaseAccessor<AppDatabase>
    with _$DevicesDaoMixin {
  DevicesDao(super.db);

  Future<DeviceRow?> getByUid(String deviceUid) {
    return (select(devicesTable)
          ..where((t) => t.deviceUid.equals(deviceUid)))
        .getSingleOrNull();
  }

  /// Records/refreshes this device's identity. The label is set once (first
  /// write wins — it's the stable label); subsequent calls only bump
  /// last_seen_at and re-queue for sync. Cheap enough to call on every write.
  Future<void> touch({
    required String deviceUid,
    required String businessId,
    required String label,
    required String platform,
  }) async {
    final existing = await getByUid(deviceUid);
    final now = DateTime.now();
    if (existing == null) {
      await into(devicesTable).insert(
        DevicesTableCompanion.insert(
          deviceUid: deviceUid,
          businessId: businessId,
          label: label,
          platform: Value(platform),
          firstSeenAt: Value(now),
          lastSeenAt: Value(now),
        ),
      );
      return;
    }
    // Only touch last_seen — keep the first-resolved label stable.
    await (update(devicesTable)
          ..where((t) => t.deviceUid.equals(deviceUid)))
        .write(
      DevicesTableCompanion(
        lastSeenAt: Value(now),
        syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
      ),
    );
  }

  /// Every known device for a business (verify UI / device management).
  Future<List<DeviceRow>> getByBusiness(String businessId) {
    return (select(devicesTable)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.desc(t.lastSeenAt)]))
        .get();
  }

  /// uid → label map for a business (alert/verify display resolution).
  Future<Map<String, String>> labelsByBusiness(String businessId) async {
    final rows = await getByBusiness(businessId);
    return {for (final r in rows) r.deviceUid: r.label};
  }

  Future<List<DeviceRow>> getPendingSync() {
    return (select(devicesTable)
          ..where(
            (t) => t.syncStatus.isIn([
              SyncStatus.pendingUpload.toInt(),
              SyncStatus.pendingUpdate.toInt(),
              SyncStatus.failed.toInt(),
            ]),
          )
          ..limit(200))
        .get();
  }

  Future<void> updateSyncStatus({
    required String deviceUid,
    required SyncStatus status,
    String? error,
  }) {
    return (update(devicesTable)
          ..where((t) => t.deviceUid.equals(deviceUid)))
        .write(
      DevicesTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(devicesTable).insertOnConflictUpdate(
      DevicesTableCompanion.insert(
        deviceUid: row['device_uid'] as String,
        businessId: row['business_id'] as String,
        label: row['label'] as String? ?? 'Unknown device',
        platform: Value(row['platform'] as String? ?? 'unknown'),
        firstSeenAt: Value(
          row['first_seen_at'] != null
              ? DateTime.parse(row['first_seen_at'] as String)
              : DateTime.now(),
        ),
        lastSeenAt: Value(
          row['last_seen_at'] != null
              ? DateTime.parse(row['last_seen_at'] as String)
              : DateTime.now(),
        ),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
  }

  Future<void> clearAll() => delete(devicesTable).go();
}
