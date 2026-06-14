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
import 'package:pos/core/database/tables/draft_sales_table.dart';
import 'package:pos/core/database/tables/draft_sale_items_table.dart';
import 'package:pos/core/database/tables/inventory_levels_table.dart';
import 'package:pos/core/database/tables/receipt_settings_table.dart';
import 'package:pos/core/database/tables/stock_ledger_table.dart';
import 'package:pos/core/database/tables/audit_logs_table.dart';
import 'package:pos/core/database/tables/employees_table.dart';
import 'package:pos/core/database/tables/employee_permissions_table.dart';
import 'package:pos/core/database/tables/business_modules_table.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/database/daos/employee_permissions_dao.dart';
import 'package:pos/core/database/daos/business_modules_dao.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/expenses_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/database/daos/draft_sales_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/receipt_settings_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/database/daos/suppliers_dao.dart';
import 'package:pos/core/database/daos/purchase_orders_dao.dart';
import 'package:pos/core/database/daos/purchase_order_lines_dao.dart';
import 'package:pos/core/database/tables/suppliers_table.dart';
import 'package:pos/core/database/tables/purchase_orders_table.dart';
import 'package:pos/core/database/tables/purchase_order_lines_table.dart';
import 'package:pos/core/database/tables/recipe_lines_table.dart';
import 'package:pos/core/database/daos/recipe_lines_dao.dart';
import 'package:pos/core/database/tables/sync_state_table.dart';
import 'package:pos/core/database/daos/sync_state_dao.dart';

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
    DraftSalesTable,
    DraftSaleItemsTable,
    InventoryLevelsTable,
    StockLedgerTable,
    ReceiptSettingsTable,
    AuditLogsTable,
    EmployeesTable,
    EmployeePermissionsTable,
    BusinessModulesTable,
    SuppliersTable,
    PurchaseOrdersTable,
    PurchaseOrderLinesTable,
    RecipeLinesTable,
    SyncStateTable,
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
    DraftSalesDao,
    InventoryLevelsDao,
    StockLedgerDao,
    ReceiptSettingsDao,
    AuditLogsDao,
    EmployeesDao,
    EmployeePermissionsDao,
    BusinessModulesDao,
    SuppliersDao,
    PurchaseOrdersDao,
    PurchaseOrderLinesDao,
    RecipeLinesDao,
    SyncStateDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(db_connect.openDatabaseConnection());

  /// Test-only constructor that accepts an explicit (e.g. in-memory) executor.
  AppDatabase.forTesting(super.executor);

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
  int get schemaVersion => 39;

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
            await customStatement('ALTER TABLE products ADD COLUMN tax REAL');
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
            'ALTER TABLE auth_context ADD COLUMN avatar_url TEXT;',
          );
        }
        if (from < 23) {
          await m.createTable(receiptSettingsTable);
        }
        if (from < 24) {
          await m.createTable(auditLogsTable);
        }
        if (from < 25) {
          await m.createTable(employeesTable);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_employees_business ON employees(business_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_employees_branch ON employees(branch_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_employees_sync ON employees(sync_status)',
          );
        }
        if (from < 26) {
          await m.createTable(employeePermissionsTable);
        }
        if (from < 27) {
          try {
            await customStatement('ALTER TABLE branches ADD COLUMN location TEXT');
          } catch (_) {}
        }
        if (from < 28) {
          await m.createTable(businessModulesTable);
        }
        if (from < 29) {
          // Add columns that were added to EmployeesTable after the initial
          // v25 creation but never had their own migration step.
          // Each is wrapped in try/catch so devices that already have the
          // column (e.g. fresh installs at v25+) don't throw.
          for (final sql in [
            'ALTER TABLE employees ADD COLUMN auth_user_id TEXT',
            'ALTER TABLE employees ADD COLUMN role_id TEXT',
            'ALTER TABLE employees ADD COLUMN role_name TEXT',
            'ALTER TABLE employees ADD COLUMN last_sync_attempt INTEGER',
            'ALTER TABLE employees ADD COLUMN sync_error TEXT',
          ]) {
            try {
              await customStatement(sql);
            } catch (_) {}
          }
        }
        if (from < 30) {
          // The v25 createTable call used whatever EmployeesTable looked like
          // at deploy time. Columns added to the Dart class afterward were
          // never backfilled for existing devices. Attempt to add every column
          // in the current schema; try/catch silently skips ones that exist.
          for (final sql in [
            'ALTER TABLE employees ADD COLUMN user_id TEXT',
            'ALTER TABLE employees ADD COLUMN full_name TEXT',
            'ALTER TABLE employees ADD COLUMN branch_id TEXT',
            'ALTER TABLE employees ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
            'ALTER TABLE employees ADD COLUMN created_at INTEGER',
            'ALTER TABLE employees ADD COLUMN sync_status INTEGER NOT NULL DEFAULT 0',
            // These were added in v29 but are included here for devices that
            // somehow skipped v29 or had it fail mid-run.
            'ALTER TABLE employees ADD COLUMN auth_user_id TEXT',
            'ALTER TABLE employees ADD COLUMN role_id TEXT',
            'ALTER TABLE employees ADD COLUMN role_name TEXT',
            'ALTER TABLE employees ADD COLUMN last_sync_attempt INTEGER',
            'ALTER TABLE employees ADD COLUMN sync_error TEXT',
          ]) {
            try {
              await customStatement(sql);
            } catch (_) {}
          }
        }
        if (from < 32) {
          try {
            await customStatement('ALTER TABLE employees ADD COLUMN email TEXT');
          } catch (_) {}
        }
        if (from < 31) {
          // The original v25 employees table was created with an employee_code
          // column (NOT NULL, no default) that was later removed from the Dart
          // schema. SQLite does not support DROP COLUMN or ALTER COLUMN, so the
          // only way to remove a NOT NULL column is to recreate the table.
          // All current-schema columns are carried forward; employee_code is
          // intentionally discarded.
          await customStatement(
            'ALTER TABLE employees RENAME TO employees_old',
          );
          await m.createTable(employeesTable);
          await customStatement('''
            INSERT INTO employees (
              id, business_id, user_id, auth_user_id, full_name,
              role_id, role_name, branch_id,
              is_active, created_at, sync_status,
              last_sync_attempt, sync_error
            )
            SELECT
              id, business_id, user_id, auth_user_id, full_name,
              role_id, role_name, branch_id,
              COALESCE(is_active, 1),
              created_at,
              COALESCE(sync_status, 0),
              last_sync_attempt, sync_error
            FROM employees_old
          ''');
          await customStatement('DROP TABLE employees_old');
        }
        if (from < 33) {
          // Held / suspended sales (local-only). Purely additive — rollback is
          // simply dropping these two tables.
          await m.createTable(draftSalesTable);
          await m.createTable(draftSaleItemsTable);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_draft_sales_status '
            'ON draft_sales(status)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_draft_sale_items_draft '
            'ON draft_sale_items(draft_id)',
          );
        }
        if (from < 34) {
          // Procurement module foundation (Phase 1).
          // Two additive columns on stock_ledger for source traceability:
          //   source_type — opaque tag e.g. 'goods_receipt', 'sale', 'manual'
          //   source_id   — ID of the originating document (NO foreign key)
          // Both are nullable; all pre-v34 rows remain valid with NULL values.
          for (final sql in [
            'ALTER TABLE stock_ledger ADD COLUMN source_type TEXT',
            'ALTER TABLE stock_ledger ADD COLUMN source_id TEXT',
          ]) {
            try {
              await customStatement(sql);
            } catch (_) {}
          }
          // Suppliers table — present unconditionally; rows only written when
          // the `procurement` module is enabled.
          await m.createTable(suppliersTable);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_suppliers_business '
            'ON suppliers(business_id)',
          );
        }

        if (from < 35) {
          // Procurement Phase 2: Purchase Orders + Lines tables.
          await m.createTable(purchaseOrdersTable);
          await m.createTable(purchaseOrderLinesTable);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_po_business '
            'ON purchase_orders(business_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_po_lines_po '
            'ON purchase_order_lines(purchase_order_id)',
          );
        }

        if (from < 36) {
          // Ingredient / recipe (BOM) module. Fully additive.
          //   products.type            — 'product' | 'ingredient'
          //   products.tracking_method — 'product_stock' | 'recipe' | 'service'
          //   product_variants.unit    — UOM (g/kg/ml/L/pcs)
          // Defaults keep every existing row behaving exactly as before.
          for (final sql in [
            "ALTER TABLE products ADD COLUMN type TEXT NOT NULL DEFAULT 'product'",
            "ALTER TABLE products ADD COLUMN tracking_method TEXT NOT NULL "
                "DEFAULT 'product_stock'",
            'ALTER TABLE product_variants ADD COLUMN unit TEXT',
          ]) {
            try {
              await customStatement(sql);
            } catch (_) {}
          }
          // Recipe lines — present unconditionally; rows only written when the
          // `recipes` module is enabled. Rollback = drop this table.
          await m.createTable(recipeLinesTable);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_recipe_lines_variant '
            'ON recipe_lines(product_variant_id)',
          );
        }

        if (from < 37) {
          // Stock-ledger source traceability. v34 added these columns via ALTER
          // for upgrading devices, but fresh installs at v34–v36 created the
          // table without them (the Drift class didn't declare them yet). They
          // are now part of the schema; add them here, tolerating the devices
          // that already have them from v34.
          for (final sql in [
            'ALTER TABLE stock_ledger ADD COLUMN source_type TEXT',
            'ALTER TABLE stock_ledger ADD COLUMN source_id TEXT',
          ]) {
            try {
              await customStatement(sql);
            } catch (_) {}
          }
        }

        if (from < 38) {
          // Delta-sync watermark store. Purely additive; rollback = drop table.
          await m.createTable(syncStateTable);
        }

        if (from < 39) {
          // Tiebreak id for the (timestamp, id) keyset cursor. Additive.
          await m.addColumn(syncStateTable, syncStateTable.lastPulledId);
        }
      },
    );
  }
}
