// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_settings_dao.dart';

// ignore_for_file: type=lint
mixin _$RefundSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RefundSettingsTableTable get refundSettingsTable =>
      attachedDatabase.refundSettingsTable;
  RefundSettingsDaoManager get managers => RefundSettingsDaoManager(this);
}

class RefundSettingsDaoManager {
  final _$RefundSettingsDaoMixin _db;
  RefundSettingsDaoManager(this._db);
  $$RefundSettingsTableTableTableManager get refundSettingsTable =>
      $$RefundSettingsTableTableTableManager(
        _db.attachedDatabase,
        _db.refundSettingsTable,
      );
}
