import 'package:drift/drift.dart';

import 'connection/connection.dart' as db_connect;

import 'package:pos/core/database/tables/auth_context_table.dart';
import 'package:pos/core/database/tables/business_templates_table.dart';
import 'package:pos/core/database/tables/businesses_table.dart';
import 'package:pos/core/database/tables/branches_table.dart';
import 'package:pos/core/database/tables/categories_table.dart';
import 'package:pos/core/database/tables/expenses_table.dart';
import 'package:pos/core/database/tables/products_table.dart';
import 'package:pos/core/database/tables/product_variants_table.dart';
import 'package:pos/core/database/tables/transactions_table.dart';
import 'package:pos/core/database/tables/transaction_items_table.dart';
import 'package:pos/core/database/tables/inventory_levels_table.dart';
import 'package:pos/core/database/tables/receipt_settings_table.dart';
import 'package:pos/core/database/tables/stock_ledger_table.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/expenses_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/receipt_settings_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AuthContextTable,
    BusinessTemplatesTable,
    BusinessesTable,
    BranchesTable,
    CategoriesTable,
    ExpensesTable,
    ProductsTable,
    ProductVariantsTable,
    TransactionsTable,
    TransactionItemsTable,
    InventoryLevelsTable,
    StockLedgerTable,
    ReceiptSettingsTable,
  ],
  daos: [
    AuthContextDao,
    BusinessTemplatesDao,
    BusinessesDao,
    BranchesDao,
    CategoriesDao,
    ExpensesDao,
    ProductsDao,
    ProductVariantsDao,
    TransactionsDao,
    InventoryLevelsDao,
    StockLedgerDao,
    ReceiptSettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(db_connect.openDatabaseConnection());

  /// Wait for the database connection to be ready (especially important on web with WASM).
  /// Returns immediately on native platforms. On web, waits for WASM to initialize.
  Future<void> ensureReady() async {
    try {
      await customSelect('SELECT 1').get();
    } catch (e) {
      throw Exception('Database initialization failed: $e');
    }
  }

  @override
  int get schemaVersion => 23;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(branchesTable);
        }
        if (from < 3) {
          await m.createTable(authContextTable);
        }
        if (from < 4) {
          await m.addColumn(authContextTable, authContextTable.roleName);
        }
        if (from < 5) {
          await m.addColumn(authContextTable, authContextTable.branchId);
          await m.addColumn(authContextTable, authContextTable.branchName);
        }
        if (from < 6) {
          await m.addColumn(
            authContextTable,
            authContextTable.businessTemplateId,
          );
          await m.addColumn(
            authContextTable,
            authContextTable.businessTemplateName,
          );
        }
        if (from < 7) {
          await m.createTable(categoriesTable);
        }
        if (from < 8) {
          await m.createTable(productsTable);
          await m.createTable(productVariantsTable);
        }
        if (from < 9) {
          try {
            await customStatement(
              'ALTER TABLE products ADD COLUMN tax REAL',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN track_expiry INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN expiry_date TEXT',
            );
          } catch (_) {}
        }
        if (from < 10) {
          try {
            await customStatement(
              "ALTER TABLE products ADD COLUMN sell_by TEXT NOT NULL DEFAULT 'unit'",
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN stock_decimal REAL',
            );
          } catch (_) {}
        }
        if (from < 11) {
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN retail_price REAL',
            );
          } catch (_) {}
        }
        if (from < 12) {
          await m.createTable(transactionsTable);
          await m.createTable(transactionItemsTable);
        }
        if (from < 13) {
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN low_stock_alert INTEGER',
            );
          } catch (_) {}
        }
        if (from < 14) {
          try {
            await customStatement(
              'ALTER TABLE products ADD COLUMN image_path TEXT',
            );
          } catch (_) {}
        }
        if (from < 15) {
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN track_stock INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
        }
        if (from < 16) {
          // NOTE: v16 created inventory_levels and stock_ledger with nullable branchId.
          // v17 and v18 below recreate them with the correct non-nullable schema.
          // Devices upgrading from <16 skip straight to v17/v18 which recreate correctly.
          await m.createTable(inventoryLevelsTable);
          await m.createTable(stockLedgerTable);
        }
        if (from < 17) {
          // Recreate inventory_levels:
          //   • branchId: nullable → NOT NULL (no more "global" stock rows)
          //   • Add quantity_decimal (for sellBy='fraction' products)
          //   • Add low_stock_alert_override (per-branch threshold)
          // NULL-branch rows from v16 are intentionally discarded — they are
          // pre-branch-era artifacts with no real stock data.
          await customStatement(
            'ALTER TABLE inventory_levels RENAME TO inventory_levels_old',
          );
          await m.createTable(inventoryLevelsTable);
          await customStatement('''
            INSERT INTO inventory_levels
              (id, variant_id, branch_id, business_id, quantity,
               quantity_decimal, low_stock_alert_override, sync_status, local_updated_at)
            SELECT
              variant_id || ':' || branch_id,
              variant_id, branch_id, business_id, quantity,
              NULL, NULL, sync_status, local_updated_at
            FROM inventory_levels_old
            WHERE branch_id IS NOT NULL
          ''');
          await customStatement('DROP TABLE inventory_levels_old');
        }
        if (from < 18) {
          // Recreate stock_ledger:
          //   • branchId: nullable → NOT NULL (NULL rows get sentinel 'unknown')
          //   • quantity: INTEGER → REAL (supports fractional sellBy='fraction' products)
          //   • Add quantity_before / quantity_after (stock snapshots for fraud detection)
          // All existing rows are preserved. Historical rows have NULL snapshots.
          await customStatement(
            'ALTER TABLE stock_ledger RENAME TO stock_ledger_old',
          );
          await m.createTable(stockLedgerTable);
          await customStatement('''
            INSERT INTO stock_ledger
              (id, variant_id, product_id, branch_id, business_id, change_type,
               quantity, quantity_before, quantity_after, reason, note,
               created_at, sync_status)
            SELECT
              id, variant_id, product_id,
              COALESCE(branch_id, 'unknown'),
              business_id, change_type,
              CAST(quantity AS REAL),
              NULL, NULL,
              reason, note, created_at, sync_status
            FROM stock_ledger_old
          ''');
          await customStatement('DROP TABLE stock_ledger_old');
        }
        if (from < 20) {
          // Add business_id column to transactions for proper multi-account isolation.
          // Backfill via branch → business join; rows with null branch_id stay null
          // (they predate branch support and belong to the only business on device).
          try {
            await customStatement(
              'ALTER TABLE transactions ADD COLUMN business_id TEXT',
            );
          } catch (_) {}
          try {
            await customStatement('''
              UPDATE transactions
              SET business_id = (
                SELECT b.business_id FROM branches b
                WHERE b.id = transactions.branch_id
              )
              WHERE branch_id IS NOT NULL AND business_id IS NULL
            ''');
          } catch (_) {}
        }
        if (from < 19) {
          // Recreate product_variants:
          //   • expiry_date: TEXT (ISO 8601) → INTEGER (Unix epoch ms, Drift DateTimeColumn)
          // All other columns are unchanged. The julianday conversion handles NULL safely.
          await customStatement(
            'ALTER TABLE product_variants RENAME TO product_variants_old',
          );
          await m.createTable(productVariantsTable);
          await customStatement('''
            INSERT INTO product_variants
              (id, product_id, business_id, name, price, cost_price, retail_price,
               stock, sku, barcode, stock_decimal, low_stock_alert, track_stock,
               track_expiry, expiry_date, is_active, sync_status,
               last_sync_attempt, sync_error, local_updated_at)
            SELECT
              id, product_id, business_id, name, price, cost_price, retail_price,
              stock, sku, barcode, stock_decimal, low_stock_alert, track_stock,
              track_expiry,
              CASE
                WHEN expiry_date IS NULL THEN NULL
                ELSE CAST((julianday(expiry_date) - 2440587.5) * 86400000 AS INTEGER)
              END,
              is_active, sync_status,
              last_sync_attempt, sync_error, local_updated_at
            FROM product_variants_old
          ''');
          await customStatement('DROP TABLE product_variants_old');
        }
        if (from < 21) {
          await m.createTable(expensesTable);
        }
        if (from < 22) {
          await customStatement(
              'ALTER TABLE auth_context ADD COLUMN avatar_url TEXT;');
        }
        if (from < 23) {
          await m.createTable(receiptSettingsTable);
        }
      },
    );
  }
}

