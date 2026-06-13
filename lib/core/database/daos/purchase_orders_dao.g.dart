// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_orders_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchaseOrdersDaoMixin on DatabaseAccessor<AppDatabase> {
  $PurchaseOrdersTableTable get purchaseOrdersTable =>
      attachedDatabase.purchaseOrdersTable;
  $PurchaseOrderLinesTableTable get purchaseOrderLinesTable =>
      attachedDatabase.purchaseOrderLinesTable;
  PurchaseOrdersDaoManager get managers => PurchaseOrdersDaoManager(this);
}

class PurchaseOrdersDaoManager {
  final _$PurchaseOrdersDaoMixin _db;
  PurchaseOrdersDaoManager(this._db);
  $$PurchaseOrdersTableTableTableManager get purchaseOrdersTable =>
      $$PurchaseOrdersTableTableTableManager(
        _db.attachedDatabase,
        _db.purchaseOrdersTable,
      );
  $$PurchaseOrderLinesTableTableTableManager get purchaseOrderLinesTable =>
      $$PurchaseOrderLinesTableTableTableManager(
        _db.attachedDatabase,
        _db.purchaseOrderLinesTable,
      );
}
