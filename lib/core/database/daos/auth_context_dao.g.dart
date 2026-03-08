// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_context_dao.dart';

// ignore_for_file: type=lint
mixin _$AuthContextDaoMixin on DatabaseAccessor<AppDatabase> {
  $AuthContextTableTable get authContextTable =>
      attachedDatabase.authContextTable;
  AuthContextDaoManager get managers => AuthContextDaoManager(this);
}

class AuthContextDaoManager {
  final _$AuthContextDaoMixin _db;
  AuthContextDaoManager(this._db);
  $$AuthContextTableTableTableManager get authContextTable =>
      $$AuthContextTableTableTableManager(
        _db.attachedDatabase,
        _db.authContextTable,
      );
}
