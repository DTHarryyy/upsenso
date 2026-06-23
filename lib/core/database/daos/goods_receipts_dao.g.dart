// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goods_receipts_dao.dart';

// ignore_for_file: type=lint
mixin _$GoodsReceiptsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GoodsReceiptsTableTable get goodsReceiptsTable =>
      attachedDatabase.goodsReceiptsTable;
  GoodsReceiptsDaoManager get managers => GoodsReceiptsDaoManager(this);
}

class GoodsReceiptsDaoManager {
  final _$GoodsReceiptsDaoMixin _db;
  GoodsReceiptsDaoManager(this._db);
  $$GoodsReceiptsTableTableTableManager get goodsReceiptsTable =>
      $$GoodsReceiptsTableTableTableManager(
        _db.attachedDatabase,
        _db.goodsReceiptsTable,
      );
}
