import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:pos/core/database/tables/auth_context_table.dart';
import 'package:pos/core/database/tables/business_templates_table.dart';
import 'package:pos/core/database/tables/businesses_table.dart';
import 'package:pos/core/database/tables/branches_table.dart';
import 'package:pos/core/database/tables/categories_table.dart';
import 'package:pos/core/database/tables/products_table.dart';
import 'package:pos/core/database/tables/product_variants_table.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AuthContextTable,
    BusinessTemplatesTable,
    BusinessesTable,
    BranchesTable,
    CategoriesTable,
    ProductsTable,
    ProductVariantsTable,
  ],
  daos: [
    AuthContextDao,
    BusinessTemplatesDao,
    BusinessesDao,
    BranchesDao,
    CategoriesDao,
    ProductsDao,
    ProductVariantsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 11;

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
          await customStatement(
            'ALTER TABLE products ADD COLUMN tax REAL',
          );
          await customStatement(
            'ALTER TABLE product_variants ADD COLUMN track_expiry INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            'ALTER TABLE product_variants ADD COLUMN expiry_date TEXT',
          );
        }
        if (from < 10) {
          await customStatement(
            "ALTER TABLE products ADD COLUMN sell_by TEXT NOT NULL DEFAULT 'unit'",
          );
          await customStatement(
            'ALTER TABLE product_variants ADD COLUMN stock_decimal REAL',
          );
        }
        if (from < 11) {
          await customStatement(
            'ALTER TABLE product_variants ADD COLUMN retail_price REAL',
          );
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pos_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
