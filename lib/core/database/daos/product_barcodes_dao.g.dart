// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_barcodes_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductBarcodesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductBarcodesTableTable get productBarcodesTable =>
      attachedDatabase.productBarcodesTable;
  ProductBarcodesDaoManager get managers => ProductBarcodesDaoManager(this);
}

class ProductBarcodesDaoManager {
  final _$ProductBarcodesDaoMixin _db;
  ProductBarcodesDaoManager(this._db);
  $$ProductBarcodesTableTableTableManager get productBarcodesTable =>
      $$ProductBarcodesTableTableTableManager(
        _db.attachedDatabase,
        _db.productBarcodesTable,
      );
}
