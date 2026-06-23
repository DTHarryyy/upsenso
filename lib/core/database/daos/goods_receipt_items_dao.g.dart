// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goods_receipt_items_dao.dart';

// ignore_for_file: type=lint
mixin _$GoodsReceiptItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GoodsReceiptItemsTableTable get goodsReceiptItemsTable =>
      attachedDatabase.goodsReceiptItemsTable;
  GoodsReceiptItemsDaoManager get managers => GoodsReceiptItemsDaoManager(this);
}

class GoodsReceiptItemsDaoManager {
  final _$GoodsReceiptItemsDaoMixin _db;
  GoodsReceiptItemsDaoManager(this._db);
  $$GoodsReceiptItemsTableTableTableManager get goodsReceiptItemsTable =>
      $$GoodsReceiptItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.goodsReceiptItemsTable,
      );
}
