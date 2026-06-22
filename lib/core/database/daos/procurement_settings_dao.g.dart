// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'procurement_settings_dao.dart';

// ignore_for_file: type=lint
mixin _$ProcurementSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProcurementSettingsTableTable get procurementSettingsTable =>
      attachedDatabase.procurementSettingsTable;
  ProcurementSettingsDaoManager get managers =>
      ProcurementSettingsDaoManager(this);
}

class ProcurementSettingsDaoManager {
  final _$ProcurementSettingsDaoMixin _db;
  ProcurementSettingsDaoManager(this._db);
  $$ProcurementSettingsTableTableTableManager get procurementSettingsTable =>
      $$ProcurementSettingsTableTableTableManager(
        _db.attachedDatabase,
        _db.procurementSettingsTable,
      );
}
