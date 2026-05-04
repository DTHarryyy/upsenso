// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_settings_dao.dart';

// ignore_for_file: type=lint
mixin _$ReceiptSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReceiptSettingsTableTable get receiptSettingsTable =>
      attachedDatabase.receiptSettingsTable;
  ReceiptSettingsDaoManager get managers => ReceiptSettingsDaoManager(this);
}

class ReceiptSettingsDaoManager {
  final _$ReceiptSettingsDaoMixin _db;
  ReceiptSettingsDaoManager(this._db);
  $$ReceiptSettingsTableTableTableManager get receiptSettingsTable =>
      $$ReceiptSettingsTableTableTableManager(
        _db.attachedDatabase,
        _db.receiptSettingsTable,
      );
}
