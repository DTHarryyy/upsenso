// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_sales_dao.dart';

// ignore_for_file: type=lint
mixin _$DraftSalesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DraftSalesTableTable get draftSalesTable => attachedDatabase.draftSalesTable;
  $DraftSaleItemsTableTable get draftSaleItemsTable =>
      attachedDatabase.draftSaleItemsTable;
  DraftSalesDaoManager get managers => DraftSalesDaoManager(this);
}

class DraftSalesDaoManager {
  final _$DraftSalesDaoMixin _db;
  DraftSalesDaoManager(this._db);
  $$DraftSalesTableTableTableManager get draftSalesTable =>
      $$DraftSalesTableTableTableManager(
        _db.attachedDatabase,
        _db.draftSalesTable,
      );
  $$DraftSaleItemsTableTableTableManager get draftSaleItemsTable =>
      $$DraftSaleItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.draftSaleItemsTable,
      );
}
