// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_modules_dao.dart';

// ignore_for_file: type=lint
mixin _$BusinessModulesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BusinessModulesTableTable get businessModulesTable =>
      attachedDatabase.businessModulesTable;
  BusinessModulesDaoManager get managers => BusinessModulesDaoManager(this);
}

class BusinessModulesDaoManager {
  final _$BusinessModulesDaoMixin _db;
  BusinessModulesDaoManager(this._db);
  $$BusinessModulesTableTableTableManager get businessModulesTable =>
      $$BusinessModulesTableTableTableManager(
        _db.attachedDatabase,
        _db.businessModulesTable,
      );
}
