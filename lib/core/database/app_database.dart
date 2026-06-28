import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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
import 'package:pos/core/database/tables/invoice_sequences_table.dart';
import 'package:pos/core/database/daos/invoice_sequences_dao.dart';
import 'package:pos/core/database/tables/po_number_sequences_table.dart';
import 'package:pos/core/database/daos/po_number_sequences_dao.dart';
import 'package:pos/core/database/tables/procurement_settings_table.dart';
import 'package:pos/core/database/daos/procurement_settings_dao.dart';
import 'package:pos/core/database/tables/goods_receipts_table.dart';
import 'package:pos/core/database/daos/goods_receipts_dao.dart';
import 'package:pos/core/database/tables/goods_receipt_items_table.dart';
import 'package:pos/core/database/daos/goods_receipt_items_dao.dart';
import 'package:pos/core/database/tables/refunds_table.dart';
import 'package:pos/core/database/tables/refund_items_table.dart';
import 'package:pos/core/database/daos/refunds_dao.dart';
import 'package:pos/core/database/tables/refund_settings_table.dart';
import 'package:pos/core/database/daos/refund_settings_dao.dart';

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
    InvoiceSequencesTable,
    PoNumberSequencesTable,
    ProcurementSettingsTable,
    GoodsReceiptsTable,
    GoodsReceiptItemsTable,
    RefundsTable,
    RefundItemsTable,
    RefundSettingsTable,
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
    InvoiceSequencesDao,
    PoNumberSequencesDao,
    ProcurementSettingsDao,
    GoodsReceiptsDao,
    GoodsReceiptItemsDao,
    RefundsDao,
    RefundSettingsDao,
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
    } catch (e, st) {
      debugPrint('[AppDatabase] Error in ensureReady: $e\n$st');
      throw Exception('Database initialization failed: $e');
    }
  }

  @override
  int get schemaVersion => 51;

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
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN track_expiry INTEGER NOT NULL DEFAULT 0',
            );
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN expiry_date TEXT',
            );
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
        }
        if (from < 10) {
          try {
            await customStatement(
              "ALTER TABLE products ADD COLUMN sell_by TEXT NOT NULL DEFAULT 'unit'",
            );
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN stock_decimal REAL',
            );
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
        }
        if (from < 11) {
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN retail_price REAL',
            );
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
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
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
        }
        if (from < 14) {
          try {
            await customStatement(
              'ALTER TABLE products ADD COLUMN image_path TEXT',
            );
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
        }
        if (from < 15) {
          try {
            await customStatement(
              'ALTER TABLE product_variants ADD COLUMN track_stock INTEGER NOT NULL DEFAULT 0',
            );
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
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
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
          try {
            await customStatement('''
              UPDATE transactions
              SET business_id = (
                SELECT b.business_id FROM branches b
                WHERE b.id = transactions.branch_id
              )
              WHERE branch_id IS NOT NULL AND business_id IS NULL
            ''');
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
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
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
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
            } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
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
            } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
          }
        }
        if (from < 32) {
          try {
            await customStatement('ALTER TABLE employees ADD COLUMN email TEXT');
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
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
            } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
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
            } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
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
            } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
          }
        }

        if (from < 38) {
          // Delta-sync watermark store. Purely additive; rollback = drop table.
          // createTable uses the CURRENT schema, so a device jumping straight
          // from <38 already gets last_pulled_id here — the v39 step then tolerates
          // the duplicate. Guarded so a partially-applied prior run can't wedge it.
          try {
            await m.createTable(syncStateTable);
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
        }

        if (from < 39) {
          // Tiebreak id for the (timestamp, id) keyset cursor. Idempotent: when
          // v38's createTable above already added it (current schema), this ALTER
          // throws "duplicate column" — tolerate it. Only devices that created
          // sync_state under the original v38 (no id column) actually add it here.
          try {
            await customStatement(
              'ALTER TABLE sync_state ADD COLUMN last_pulled_id TEXT',
            );
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
        }

        if (from < 40) {
          // Sequential invoice numbers. Two additive operations:
          //   • invoice_number column on transactions (nullable — pre-feature rows stay NULL)
          //   • invoice_sequences table for the per-business offline counter
          // Rollback: drop the table + drop the column (no data loss for old rows).
          try {
            await customStatement(
              'ALTER TABLE transactions ADD COLUMN invoice_number TEXT',
            );
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
          try {
            await customStatement('''
              CREATE TABLE IF NOT EXISTS invoice_sequences (
                business_id TEXT NOT NULL,
                month_key   TEXT NOT NULL,
                last_value  INTEGER NOT NULL DEFAULT 0,
                updated_at  INTEGER NOT NULL DEFAULT (CAST(strftime('%s','now') * 1000 AS INTEGER)),
                PRIMARY KEY (business_id, month_key)
              )
            ''');
          } catch (e, st) {
            // Idempotent migration step: column/table likely already exists.
            // Log so a genuine schema failure is never silently lost.
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
        }

        if (from < 41) {
          // Bring three tables physically in line with the generated schema so
          // the in-app schema validator stops reporting drift:
          //   • transactions / product_variants — invoice_number & unit were
          //     added by raw ALTER (appended out of declared order)
          //   • invoice_sequences.updated_at — created with a milliseconds
          //     default; Drift expects seconds (updated_at is always written
          //     explicitly and never read, so existing values are harmless)
          // alterTable rebuilds each table from the current Dart schema and
          // copies all rows; transactions also sheds the dead, never-written
          // transaction_hash column.
          // Rollback: re-add the column with
          //   ALTER TABLE transactions ADD COLUMN transaction_hash TEXT
          // The product_variants/invoice_sequences rebuilds are non-destructive.
          try {
            await m.alterTable(TableMigration(transactionsTable));
            await m.alterTable(TableMigration(productVariantsTable));
            await m.alterTable(TableMigration(invoiceSequencesTable));
          } catch (e, st) {
            debugPrint('[AppDatabase] v41 table rebuild failed: $e\n$st');
            rethrow;
          }
        }

        if (from < 42) {
          // Refund feature: append-only header + lines, purely additive.
          // Rollback: DROP TABLE refund_items; DROP TABLE refunds;
          await m.createTable(refundsTable);
          await m.createTable(refundItemsTable);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_refunds_transaction '
            'ON refunds(transaction_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_refunds_business '
            'ON refunds(business_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_refund_items_refund '
            'ON refund_items(refund_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_refund_items_transaction_item '
            'ON refund_items(transaction_item_id)',
          );
        }

        if (from < 43) {
          // Per-line restock choice — lets a refunder mark a damaged/expired
          // return as NOT going back to sellable stock, instead of every
          // refund unconditionally restocking. Defaults true so existing
          // rows (all restocked under the old always-restock behaviour)
          // keep reading as restocked.
          try {
            await customStatement(
              'ALTER TABLE refund_items ADD COLUMN restocked INTEGER NOT NULL DEFAULT 1',
            );
          } catch (e, st) {
            debugPrint('[AppDatabase] Migration step skipped: $e\n$st');
          }
        }

        if (from < 44) {
          // Devices that reached v42 (refund_items created) before this
          // class gained the `restocked` column, then jumped straight to a
          // build with schemaVersion already at 43+ without ever passing
          // through the v43 step above (e.g. a dev hot-reload session that
          // never reconnected to the database), ended up permanently at
          // schema 43 with the column actually missing — the swallowed
          // catch above let that go unnoticed. Check for real instead of
          // guessing, and surface a genuine failure loudly instead of
          // silently leaving the column missing a second time.
          try {
            final cols = await customSelect(
              "SELECT name FROM pragma_table_info('refund_items')",
            ).get();
            final hasRestocked = cols.any(
              (r) => r.data['name'] == 'restocked',
            );
            if (!hasRestocked) {
              await customStatement(
                'ALTER TABLE refund_items ADD COLUMN restocked INTEGER NOT NULL DEFAULT 1',
              );
            }
          } catch (e, st) {
            debugPrint('[AppDatabase] v44 restocked backfill failed: $e\n$st');
            rethrow;
          }
        }

        if (from < 45) {
          // Defense-in-depth mirror of the Postgres-side
          // UNIQUE(refund_id, transaction_item_id) constraint — blocks a
          // single refund event from ever recording the same original sale
          // line twice. Refunding the same line again in a LATER, separate
          // refund event is unaffected (different refund_id).
          try {
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_refund_items_unique_line '
              'ON refund_items(refund_id, transaction_item_id)',
            );
          } catch (e, st) {
            debugPrint('[AppDatabase] v45 unique index failed: $e\n$st');
            rethrow;
          }
        }
        if (from < 46) {
          // Phase 5b — collapse the dual int/decimal stock & quantity columns
          // into a single decimal column (the "fractional footgun"). Preserve
          // any fractional value from the *_decimal mirror before dropping it;
          // SQLite's INTEGER affinity stores the non-integral result as REAL,
          // so fractions survive and the surviving column now holds doubles.
          try {
            await customStatement(
              'UPDATE product_variants SET stock = stock_decimal '
              'WHERE stock_decimal IS NOT NULL AND stock_decimal != 0',
            );
            await customStatement(
              'ALTER TABLE product_variants DROP COLUMN stock_decimal',
            );
          } catch (e, st) {
            debugPrint('[AppDatabase] v46 stock collapse skipped: $e\n$st');
          }
          try {
            await customStatement(
              'UPDATE inventory_levels SET quantity = quantity_decimal '
              'WHERE quantity_decimal IS NOT NULL AND quantity_decimal != 0',
            );
            await customStatement(
              'ALTER TABLE inventory_levels DROP COLUMN quantity_decimal',
            );
          } catch (e, st) {
            debugPrint('[AppDatabase] v46 quantity collapse skipped: $e\n$st');
          }
        }
        if (from < 47) {
          // Local counter for offline-safe sequential PO numbers
          // (PO-YYYYMM-NNNN), mirroring invoice_sequences. Additive.
          try {
            await m.createTable(poNumberSequencesTable);
          } catch (e, st) {
            debugPrint('[AppDatabase] v47 po_number_sequences create skipped: $e\n$st');
          }
        }
        if (from < 48) {
          // Per-business procurement settings (PO approval threshold). Additive.
          try {
            await m.createTable(procurementSettingsTable);
          } catch (e, st) {
            debugPrint('[AppDatabase] v48 procurement_settings create skipped: $e\n$st');
          }
        }
        if (from < 49) {
          // Landed-cost columns on purchase_orders (order-level discount +
          // shipping). Additive; default 0 so existing POs are unaffected.
          for (final col in ['discount', 'shipping']) {
            try {
              await customStatement(
                'ALTER TABLE purchase_orders ADD COLUMN $col REAL NOT NULL DEFAULT 0.0',
              );
            } catch (e, st) {
              debugPrint('[AppDatabase] v49 add $col skipped: $e\n$st');
            }
          }
        }
        if (from < 50) {
          // Goods-receipt (GRN) document tables. Additive.
          try {
            await m.createTable(goodsReceiptsTable);
            await m.createTable(goodsReceiptItemsTable);
          } catch (e, st) {
            debugPrint('[AppDatabase] v50 goods_receipts create skipped: $e\n$st');
          }
        }
        if (from < 51) {
          // Local pull-only read cache of refund_settings (Phase 5 — lets the
          // refund sheet check the approval threshold offline). Additive.
          try {
            await m.createTable(refundSettingsTable);
          } catch (e, st) {
            debugPrint('[AppDatabase] v51 refund_settings create skipped: $e\n$st');
          }
        }
      },
    );
  }
}
