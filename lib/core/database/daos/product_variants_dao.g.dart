// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_variants_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductVariantsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductVariantsTableTable get productVariantsTable =>
      attachedDatabase.productVariantsTable;
  ProductVariantsDaoManager get managers => ProductVariantsDaoManager(this);
}

class ProductVariantsDaoManager {
  final _$ProductVariantsDaoMixin _db;
  ProductVariantsDaoManager(this._db);
  $$ProductVariantsTableTableTableManager get productVariantsTable =>
      $$ProductVariantsTableTableTableManager(
        _db.attachedDatabase,
        _db.productVariantsTable,
      );
}
