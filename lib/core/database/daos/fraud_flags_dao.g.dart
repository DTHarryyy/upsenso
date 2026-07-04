// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fraud_flags_dao.dart';

// ignore_for_file: type=lint
mixin _$FraudFlagsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FraudFlagsTableTable get fraudFlagsTable => attachedDatabase.fraudFlagsTable;
  FraudFlagsDaoManager get managers => FraudFlagsDaoManager(this);
}

class FraudFlagsDaoManager {
  final _$FraudFlagsDaoMixin _db;
  FraudFlagsDaoManager(this._db);
  $$FraudFlagsTableTableTableManager get fraudFlagsTable =>
      $$FraudFlagsTableTableTableManager(
        _db.attachedDatabase,
        _db.fraudFlagsTable,
      );
}
