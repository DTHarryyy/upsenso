import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/features/inventory/data/inventory_repository.dart';

void main() {
  late AppDatabase db;
  late InventoryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = InventoryRepository(
      productsDao: ProductsDao(db),
      variantsDao: ProductVariantsDao(db),
      branchesDao: BranchesDao(db),
      levelsDao: InventoryLevelsDao(db),
      ledgerDao: StockLedgerDao(db),
    );
  });

  tearDown(() async => db.close());

  Future<void> seedVariant(
    String id, {
    required int stock,
    required bool trackStock,
  }) {
    return db
        .into(db.productVariantsTable)
        .insert(
          ProductVariantsTableCompanion.insert(
            id: id,
            productId: 'p1',
            businessId: 'biz',
            name: 'Default',
            stock: Value(stock),
            trackStock: Value(trackStock),
          ),
        );
  }

  test('flags tracked variant short on stock (branch-agnostic fallback)', () async {
    await seedVariant('v1', stock: 1, trackStock: true);

    final shortages = await repo.checkStockAvailability(
      items: [(variantId: 'v1', qty: 3)],
      branchId: null,
    );

    expect(shortages, hasLength(1));
    expect(shortages.single.variantId, 'v1');
    expect(shortages.single.available, 1);
    expect(shortages.single.requested, 3);
  });

  test('untracked variants are never flagged', () async {
    await seedVariant('v2', stock: 0, trackStock: false);

    final shortages = await repo.checkStockAvailability(
      items: [(variantId: 'v2', qty: 99)],
      branchId: null,
    );

    expect(shortages, isEmpty);
  });

  test('sufficient stock yields no shortage', () async {
    await seedVariant('v3', stock: 10, trackStock: true);

    final shortages = await repo.checkStockAvailability(
      items: [(variantId: 'v3', qty: 4)],
      branchId: null,
    );

    expect(shortages, isEmpty);
  });
}
