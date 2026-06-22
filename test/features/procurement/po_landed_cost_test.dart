import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/po_number_sequences_dao.dart';
import 'package:pos/core/database/daos/procurement_settings_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/purchase_order_lines_dao.dart';
import 'package:pos/core/database/daos/purchase_orders_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/database/daos/suppliers_dao.dart';
import 'package:pos/core/services/po_number_service.dart';
import 'package:pos/core/services/stock_movement_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/procurement/data/datasources/procurement_remote_ds.dart';
import 'package:pos/features/procurement/data/procurement_repository.dart';
import 'package:pos/features/procurement/domain/entities/po_input.dart';

/// Receiving folds order-level shipping (and discount) into the moving-average
/// cost as landed cost, distributed across the line's ordered units.
void main() {
  late AppDatabase db;
  late ProcurementRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // receiveGoods writes an audit entry through the service locator.
    if (sl.isRegistered<AuditLogService>()) sl.unregister<AuditLogService>();
    sl.registerSingleton<AuditLogService>(
      AuditLogService(
        dao: db.auditLogsDao,
        authContextDao: db.authContextDao,
        activeBusinessContext: ActiveBusinessContext(),
      ),
    );
    repo = ProcurementRepository(
      suppliersDao: SuppliersDao(db),
      purchaseOrdersDao: PurchaseOrdersDao(db),
      purchaseOrderLinesDao: PurchaseOrderLinesDao(db),
      variantsDao: ProductVariantsDao(db),
      levelsDao: InventoryLevelsDao(db),
      stockMovement: StockMovementService(
        ledgerDao: StockLedgerDao(db),
        levelsDao: InventoryLevelsDao(db),
        variantsDao: ProductVariantsDao(db),
      ),
      poNumberService: PoNumberService(
        SupabaseClient('http://localhost', 'k'),
        PoNumberSequencesDao(db),
      ),
      settingsDao: ProcurementSettingsDao(db),
      remoteDs: ProcurementRemoteDs(SupabaseClient('http://localhost', 'k')),
    );
  });

  tearDown(() async {
    await sl.reset();
    await db.close();
  });

  test('shipping is distributed into moving-average cost on receipt', () async {
    await db.productVariantsDao.insertVariant(
      ProductVariantsTableCompanion.insert(
        id: 'v1',
        productId: 'p1',
        businessId: 'biz',
        name: 'Item',
        costPrice: const Value(0),
        stock: const Value(0),
      ),
    );
    // 10 units @ 100, + 50 shipping → landed unit cost = 100 + 50/10 = 105.
    await db.purchaseOrdersDao.insert(
      PurchaseOrdersTableCompanion.insert(
        id: 'po1',
        businessId: 'biz',
        poNumber: 'PO-202606-0001',
        status: const Value('approved'),
        shipping: const Value(50),
        totalAmount: const Value(1050),
        createdById: const Value('u1'),
      ),
    );
    await db.purchaseOrderLinesDao.insertAll([
      PurchaseOrderLinesTableCompanion.insert(
        id: 'l1',
        purchaseOrderId: 'po1',
        businessId: 'biz',
        productId: 'p1',
        variantId: 'v1',
        productName: 'Item',
        variantName: 'Default',
        quantityOrdered: const Value(10),
        unitCost: const Value(100),
      ),
    ]);

    await repo.receiveGoods(
      poId: 'po1',
      branchId: 'b1',
      lines: const [
        ReceiveLineInput(
          lineId: 'l1',
          variantId: 'v1',
          productId: 'p1',
          quantityToReceive: 10,
          unitCost: 100,
        ),
      ],
    );

    final variant = await db.productVariantsDao.getById('v1');
    expect(variant!.costPrice, closeTo(105.0, 0.0001));
  });
}
