import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/refund_settings_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'refund_settings_dao.g.dart';

@DriftAccessor(tables: [RefundSettingsTable])
class RefundSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$RefundSettingsDaoMixin {
  RefundSettingsDao(super.db);

  Stream<RefundSettingsRow?> watchByBusinessId(String businessId) {
    return (select(refundSettingsTable)
          ..where((t) => t.businessId.equals(businessId)))
        .watchSingleOrNull();
  }

  Future<RefundSettingsRow?> getByBusinessId(String businessId) {
    return (select(refundSettingsTable)
          ..where((t) => t.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  Future<void> upsertFromServer({
    required String businessId,
    required bool requireApproval,
    required double threshold,
  }) {
    return into(refundSettingsTable).insertOnConflictUpdate(
      RefundSettingsTableCompanion.insert(
        id: businessId,
        businessId: businessId,
        requireApproval: Value(requireApproval),
        approvalThreshold: Value(threshold),
        updatedAt: Value(DateTime.now()),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
  }

  Future<void> clearAll() => delete(refundSettingsTable).go();
}
