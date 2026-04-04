// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_ledger_dao.dart';

// ignore_for_file: type=lint
mixin _$StockLedgerDaoMixin on DatabaseAccessor<AppDatabase> {
  $StockLedgerTableTable get stockLedgerTable =>
      attachedDatabase.stockLedgerTable;
  StockLedgerDaoManager get managers => StockLedgerDaoManager(this);
}

class StockLedgerDaoManager {
  final _$StockLedgerDaoMixin _db;
  StockLedgerDaoManager(this._db);
  $$StockLedgerTableTableTableManager get stockLedgerTable =>
      $$StockLedgerTableTableTableManager(
        _db.attachedDatabase,
        _db.stockLedgerTable,
      );
}
