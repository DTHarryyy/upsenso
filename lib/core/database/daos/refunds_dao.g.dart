// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refunds_dao.dart';

// ignore_for_file: type=lint
mixin _$RefundsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RefundsTableTable get refundsTable => attachedDatabase.refundsTable;
  $RefundItemsTableTable get refundItemsTable =>
      attachedDatabase.refundItemsTable;
  RefundsDaoManager get managers => RefundsDaoManager(this);
}

class RefundsDaoManager {
  final _$RefundsDaoMixin _db;
  RefundsDaoManager(this._db);
  $$RefundsTableTableTableManager get refundsTable =>
      $$RefundsTableTableTableManager(_db.attachedDatabase, _db.refundsTable);
  $$RefundItemsTableTableTableManager get refundItemsTable =>
      $$RefundItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.refundItemsTable,
      );
}
