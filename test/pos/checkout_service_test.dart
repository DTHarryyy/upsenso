import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/recipe_lines_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/services/checkout_service.dart';
import 'package:pos/core/services/recipe_consumption_service.dart';
import 'package:pos/core/services/stock_movement_service.dart';
import 'package:pos/features/inventory/data/inventory_repository.dart';

// Regression for H-1: completing a sale must record the transaction AND deduct
// inventory together (atomically). Previously these were two separate awaits in
// the checkout widget, so a crash between them diverged sales from stock.
void main() {
  late AppDatabase db;
  late InventoryLevelsDao levels;
  late ProductVariantsDao variants;
  late ProductsDao products;
  late TransactionsDao transactions;
  late CheckoutService checkout;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    levels = InventoryLevelsDao(db);
    variants = ProductVariantsDao(db);
    products = ProductsDao(db);
    transactions = TransactionsDao(db);

    final movement = StockMovementService(
      ledgerDao: StockLedgerDao(db),
      levelsDao: levels,
      variantsDao: variants,
    );
    final inventory = InventoryRepository(
      productsDao: products,
      variantsDao: variants,
      branchesDao: BranchesDao(db),
      levelsDao: levels,
      stockMovement: movement,
      recipeConsumption: RecipeConsumptionService(
        recipeLinesDao: RecipeLinesDao(db),
        ledgerDao: StockLedgerDao(db),
        variantsDao: variants,
        levelsDao: levels,
      ),
    );
    checkout = CheckoutService(
      db: db,
      transactionsDao: transactions,
      inventoryRepository: inventory,
    );
  });

  tearDown(() async => db.close());

  Future<void> seed() async {
    await products.insertProduct(
      ProductsTableCompanion.insert(id: 'p1', businessId: 'biz', name: 'Soda'),
    );
    await variants.insertVariant(
      ProductVariantsTableCompanion.insert(
        id: 'v1',
        productId: 'p1',
        businessId: 'biz',
        name: 'Soda',
        trackStock: const Value(true),
        stock: const Value(10),
      ),
    );
    await levels.upsertLevel(
      variantId: 'v1',
      branchId: 'b1',
      businessId: 'biz',
      quantity: 10,
    );
  }

  test('completeSale records the transaction and deducts stock together', () async {
    await seed();

    await checkout.completeSale(
      transaction: TransactionsTableCompanion.insert(
        id: 't1',
        cashierId: 'c1',
        businessId: const Value('biz'),
        branchId: const Value('b1'),
        totalAmount: 20.0,
        taxAmount: 0.0,
        subtotal: 20.0,
        itemCount: 1,
      ),
      items: [
        TransactionItemsTableCompanion.insert(
          id: 'i1',
          transactionId: 't1',
          variantId: 'v1',
          productName: 'Soda',
          variantName: 'Soda',
          unitPrice: 10.0,
          qty: 2,
          lineTotal: 20.0,
          lineTax: 0.0,
        ),
      ],
      deductions: [(variantId: 'v1', qty: 2.0)],
      businessId: 'biz',
      branchId: 'b1',
    );

    final tx = await (db.select(db.transactionsTable)
          ..where((t) => t.id.equals('t1')))
        .getSingleOrNull();
    expect(tx, isNotNull, reason: 'transaction must be persisted');

    final level = await levels.getLevel('v1', 'b1');
    expect(level!.quantity, 8, reason: 'stock must be deducted by 2');
  });
}
