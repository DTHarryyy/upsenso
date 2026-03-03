// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'businesses_dao.dart';

// ignore_for_file: type=lint
mixin _$BusinessesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BusinessesTableTable get businessesTable => attachedDatabase.businessesTable;
  BusinessesDaoManager get managers => BusinessesDaoManager(this);
}

class BusinessesDaoManager {
  final _$BusinessesDaoMixin _db;
  BusinessesDaoManager(this._db);
  $$BusinessesTableTableTableManager get businessesTable =>
      $$BusinessesTableTableTableManager(
        _db.attachedDatabase,
        _db.businessesTable,
      );
}
