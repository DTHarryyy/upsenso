import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';

// Regression for C-4: a server pull must NOT overwrite a local row that still
// has unsynced edits. Before the fix products/variants used an unconditional
// insertOnConflictUpdate, so a pull silently discarded offline price/SKU edits.
void main() {
  late AppDatabase db;
  late ProductVariantsDao variants;
  late ProductsDao products;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    variants = ProductVariantsDao(db);
    products = ProductsDao(db);
  });

  tearDown(() async => db.close());

  Map<String, dynamic> variantRow(String name, double price) => {
        'id': 'v1',
        'product_id': 'p1',
        'business_id': 'biz',
        'name': name,
        'price': price,
      };

  Map<String, dynamic> productRow(String name) => {
        'id': 'p1',
        'business_id': 'biz',
        'name': name,
      };

  test('variant with pending local edit survives a server pull', () async {
    await variants.insertVariant(
      ProductVariantsTableCompanion.insert(
        id: 'v1',
        productId: 'p1',
        businessId: 'biz',
        name: 'Local edited',
        price: const Value(99.0),
        syncStatus: const Value(1), // pendingUpdate
      ),
    );

    await variants.upsertFromServer(variantRow('Server stale', 10.0));

    final v = await variants.getById('v1');
    expect(v!.name, 'Local edited');
    expect(v.price, 99.0);
  });

  test('synced variant IS refreshed from the server', () async {
    await variants.insertVariant(
      ProductVariantsTableCompanion.insert(
        id: 'v1',
        productId: 'p1',
        businessId: 'biz',
        name: 'Old',
        price: const Value(10.0),
        syncStatus: const Value(3), // synced
      ),
    );

    await variants.upsertFromServer(variantRow('Fresh', 20.0));

    final v = await variants.getById('v1');
    expect(v!.name, 'Fresh');
    expect(v.price, 20.0);
  });

  test('product with pending local edit survives a server pull', () async {
    await products.insertProduct(
      ProductsTableCompanion.insert(
        id: 'p1',
        businessId: 'biz',
        name: 'Local edited',
        syncStatus: const Value(1), // pendingUpdate
      ),
    );

    await products.upsertFromServer(productRow('Server stale'));

    final p = await products.getById('p1');
    expect(p!.name, 'Local edited');
  });
}
