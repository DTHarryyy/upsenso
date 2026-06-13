import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/recipe_lines_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/services/recipe_consumption_service.dart';
import 'package:pos/core/services/stock_movement_service.dart';
import 'package:pos/features/inventory/data/inventory_repository.dart';

void main() {
  late AppDatabase db;
  late InventoryRepository repo;
  late InventoryLevelsDao levelsDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final variantsDao = ProductVariantsDao(db);
    levelsDao = InventoryLevelsDao(db);
    final ledgerDao = StockLedgerDao(db);
    final stockMovement = StockMovementService(
      ledgerDao: ledgerDao,
      levelsDao: levelsDao,
      variantsDao: variantsDao,
    );
    repo = InventoryRepository(
      productsDao: ProductsDao(db),
      variantsDao: variantsDao,
      branchesDao: BranchesDao(db),
      levelsDao: levelsDao,
      stockMovement: stockMovement,
      recipeConsumption: RecipeConsumptionService(
        recipeLinesDao: RecipeLinesDao(db),
        ledgerDao: ledgerDao,
        variantsDao: variantsDao,
        levelsDao: levelsDao,
      ),
    );
  });

  tearDown(() async => db.close());

  Future<void> seedProduct(
    String id, {
    String trackingMethod = 'product_stock',
  }) {
    return db.into(db.productsTable).insertOnConflictUpdate(
          ProductsTableCompanion.insert(
            id: id,
            businessId: 'biz',
            name: 'Product $id',
            trackingMethod: Value(trackingMethod),
          ),
        );
  }

  Future<void> seedVariant(
    String id, {
    required int stock,
    required bool trackStock,
    String productId = 'p1',
  }) async {
    await seedProduct(productId);
    await db.into(db.productVariantsTable).insert(
          ProductVariantsTableCompanion.insert(
            id: id,
            productId: productId,
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

  // ── service products ──────────────────────────────────────────────────────

  test('service product is never flagged regardless of stock', () async {
    await seedProduct('p_svc', trackingMethod: 'service');
    await db.into(db.productVariantsTable).insert(
          ProductVariantsTableCompanion.insert(
            id: 'v_svc',
            productId: 'p_svc',
            businessId: 'biz',
            name: 'Default',
            stock: const Value(0),
            trackStock: const Value(true),
          ),
        );

    final shortages = await repo.checkStockAvailability(
      items: [(variantId: 'v_svc', qty: 999)],
      branchId: 'branch1',
    );

    expect(shortages, isEmpty);
  });

  // ── recipe products ───────────────────────────────────────────────────────

  Future<void> seedRecipeSetup({
    required int ingredientStock,
    required double recipeQtyPerUnit,
  }) async {
    // Sellable recipe product + variant
    await seedProduct('p_recipe', trackingMethod: 'recipe');
    await db.into(db.productVariantsTable).insert(
          ProductVariantsTableCompanion.insert(
            id: 'v_recipe',
            productId: 'p_recipe',
            businessId: 'biz',
            name: 'Default',
            stock: const Value(0),
            trackStock: const Value(false),
          ),
        );

    // Ingredient product + variant
    await seedProduct('p_ing', trackingMethod: 'product_stock');
    await db.into(db.productVariantsTable).insert(
          ProductVariantsTableCompanion.insert(
            id: 'v_ing',
            productId: 'p_ing',
            businessId: 'biz',
            name: 'Default',
            stock: Value(ingredientStock),
            trackStock: const Value(true),
          ),
        );

    // Seed branch-level stock for the ingredient
    await levelsDao.upsertLevel(
      variantId: 'v_ing',
      branchId: 'branch1',
      businessId: 'biz',
      quantity: ingredientStock,
    );

    // Recipe line: 1 unit of v_recipe consumes recipeQtyPerUnit of v_ing
    await db.into(db.recipeLinesTable).insert(
          RecipeLinesTableCompanion.insert(
            id: 'rl1',
            businessId: 'biz',
            productVariantId: 'v_recipe',
            ingredientVariantId: 'v_ing',
            ingredientName: 'Ingredient',
            quantity: Value(recipeQtyPerUnit),
          ),
        );
  }

  test('recipe product flags shortage when ingredient is insufficient', () async {
    // 4 units of ingredient in stock, recipe requires 3 per unit sold
    // → can only make 1 unit (floor(4/3)=1), requesting 2 → shortage
    await seedRecipeSetup(ingredientStock: 4, recipeQtyPerUnit: 3.0);

    final shortages = await repo.checkStockAvailability(
      items: [(variantId: 'v_recipe', qty: 2)],
      branchId: 'branch1',
    );

    expect(shortages, hasLength(1));
    expect(shortages.single.variantId, 'v_recipe');
    expect(shortages.single.available, closeTo(1.33, 0.01)); // 4/3
    expect(shortages.single.requested, 2);
  });

  test('recipe product yields no shortage when ingredient is sufficient', () async {
    // 10 units of ingredient in stock, recipe requires 2 per unit sold
    // → can make 5 units, requesting 3 → no shortage
    await seedRecipeSetup(ingredientStock: 10, recipeQtyPerUnit: 2.0);

    final shortages = await repo.checkStockAvailability(
      items: [(variantId: 'v_recipe', qty: 3)],
      branchId: 'branch1',
    );

    expect(shortages, isEmpty);
  });
}
