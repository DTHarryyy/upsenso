import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/procurement_settings_table.dart';

part 'procurement_settings_dao.g.dart';

@DriftAccessor(tables: [ProcurementSettingsTable])
class ProcurementSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$ProcurementSettingsDaoMixin {
  ProcurementSettingsDao(super.db);

  Future<ProcurementSettingsTableData?> getByBusinessId(
    String businessId,
  ) {
    return (select(procurementSettingsTable)
          ..where((t) => t.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  Future<void> upsert(ProcurementSettingsTableCompanion entry) {
    return into(procurementSettingsTable)
        .insertOnConflictUpdate(entry);
  }
}
