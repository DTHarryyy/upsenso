import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/services/stock_movement_service.dart';

// Regression for C-2: a fractional (weight) product sale must deduct the exact
// quantity. Before the fix StockMovementService.apply truncated the delta to an
// int, so selling 0.5 kg deducted nothing and stock never moved.
void main() {
  late AppDatabase db;
  late InventoryLevelsDao levels;
  late ProductVariantsDao variants;
  late StockMovementService movement;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    levels = InventoryLevelsDao(db);
    variants = ProductVariantsDao(db);
    movement = StockMovementService(
      ledgerDao: StockLedgerDao(db),
      levelsDao: levels,
      variantsDao: variants,
    );
  });

  tearDown(() async => db.close());

  Future<void> seedVariant({
    required String id,
    required bool trackStock,
    double? stockDecimal,
    int stock = 0,
  }) {
    return variants.insertVariant(
      ProductVariantsTableCompanion.insert(
        id: id,
        productId: 'p1',
        businessId: 'biz',
        name: 'V $id',
        trackStock: Value(trackStock),
        stockDecimal: Value(stockDecimal),
        stock: Value(stock),
      ),
    );
  }

  test('fractional sale deducts the exact decimal amount', () async {
    await seedVariant(id: 'vf', trackStock: true, stockDecimal: 5.0, stock: 5);
    await levels.upsertLevel(
      variantId: 'vf',
      branchId: 'b1',
      businessId: 'biz',
      quantity: 5,
      quantityDecimal: 5.0,
    );

    await movement.apply(
      variantId: 'vf',
      productId: 'p1',
      businessId: 'biz',
      branchId: 'b1',
      isIncoming: false,
      quantity: 0.5,
      reason: 'Sale',
    );

    final level = await levels.getLevel('vf', 'b1');
    expect(level!.effectiveQuantity, 4.5);
  });

  test('unit sale still uses the integer path and leaves decimal null', () async {
    await seedVariant(id: 'vu', trackStock: true, stock: 10);
    await levels.upsertLevel(
      variantId: 'vu',
      branchId: 'b1',
      businessId: 'biz',
      quantity: 10,
    );

    await movement.apply(
      variantId: 'vu',
      productId: 'p1',
      businessId: 'biz',
      branchId: 'b1',
      isIncoming: false,
      quantity: 3,
      reason: 'Sale',
    );

    final level = await levels.getLevel('vu', 'b1');
    expect(level!.quantity, 7);
    expect(level.quantityDecimal, isNull);
  });

  test('fractional restock adds the exact decimal amount', () async {
    await seedVariant(id: 'vf', trackStock: true, stockDecimal: 2.0, stock: 2);
    await levels.upsertLevel(
      variantId: 'vf',
      branchId: 'b1',
      businessId: 'biz',
      quantity: 2,
      quantityDecimal: 2.0,
    );

    await movement.apply(
      variantId: 'vf',
      productId: 'p1',
      businessId: 'biz',
      branchId: 'b1',
      isIncoming: true,
      quantity: 1.25,
      reason: 'Purchase',
    );

    final level = await levels.getLevel('vf', 'b1');
    expect(level!.effectiveQuantity, 3.25);
  });
}
