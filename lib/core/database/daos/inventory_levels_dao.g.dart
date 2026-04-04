// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_levels_dao.dart';

// ignore_for_file: type=lint
mixin _$InventoryLevelsDaoMixin on DatabaseAccessor<AppDatabase> {
  $InventoryLevelsTableTable get inventoryLevelsTable =>
      attachedDatabase.inventoryLevelsTable;
  InventoryLevelsDaoManager get managers => InventoryLevelsDaoManager(this);
}

class InventoryLevelsDaoManager {
  final _$InventoryLevelsDaoMixin _db;
  InventoryLevelsDaoManager(this._db);
  $$InventoryLevelsTableTableTableManager get inventoryLevelsTable =>
      $$InventoryLevelsTableTableTableManager(
        _db.attachedDatabase,
        _db.inventoryLevelsTable,
      );
}
