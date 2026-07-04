// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devices_dao.dart';

// ignore_for_file: type=lint
mixin _$DevicesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DevicesTableTable get devicesTable => attachedDatabase.devicesTable;
  DevicesDaoManager get managers => DevicesDaoManager(this);
}

class DevicesDaoManager {
  final _$DevicesDaoMixin _db;
  DevicesDaoManager(this._db);
  $$DevicesTableTableTableManager get devicesTable =>
      $$DevicesTableTableTableManager(_db.attachedDatabase, _db.devicesTable);
}
