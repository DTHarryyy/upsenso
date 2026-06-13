// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_order_lines_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchaseOrderLinesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PurchaseOrderLinesTableTable get purchaseOrderLinesTable =>
      attachedDatabase.purchaseOrderLinesTable;
  PurchaseOrderLinesDaoManager get managers =>
      PurchaseOrderLinesDaoManager(this);
}

class PurchaseOrderLinesDaoManager {
  final _$PurchaseOrderLinesDaoMixin _db;
  PurchaseOrderLinesDaoManager(this._db);
  $$PurchaseOrderLinesTableTableTableManager get purchaseOrderLinesTable =>
      $$PurchaseOrderLinesTableTableTableManager(
        _db.attachedDatabase,
        _db.purchaseOrderLinesTable,
      );
}
