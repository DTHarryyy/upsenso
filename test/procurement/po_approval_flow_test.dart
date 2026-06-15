import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/purchase_order_lines_dao.dart';
import 'package:pos/core/database/daos/purchase_orders_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/database/daos/suppliers_dao.dart';
import 'package:pos/core/services/stock_movement_service.dart';
import 'package:pos/features/procurement/data/procurement_repository.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';

/// Phase 2 streamlined approval: an approver may approve a draft directly,
/// skipping the submit step, while the submit→approve path still works and
/// re-approving a terminal PO is rejected.
void main() {
  late AppDatabase db;
  late ProcurementRepository repo;
  late PurchaseOrdersDao poDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    poDao = PurchaseOrdersDao(db);
    final variantsDao = ProductVariantsDao(db);
    final levelsDao = InventoryLevelsDao(db);
    repo = ProcurementRepository(
      suppliersDao: SuppliersDao(db),
      purchaseOrdersDao: poDao,
      purchaseOrderLinesDao: PurchaseOrderLinesDao(db),
      variantsDao: variantsDao,
      levelsDao: levelsDao,
      stockMovement: StockMovementService(
        ledgerDao: StockLedgerDao(db),
        levelsDao: levelsDao,
        variantsDao: variantsDao,
      ),
    );
    // The repository writes audit entries via the service locator — register a
    // real one on the same in-memory DB so logging doesn't blow up.
    if (sl.isRegistered<AuditLogService>()) sl.unregister<AuditLogService>();
    sl.registerSingleton<AuditLogService>(
      AuditLogService(
        dao: AuditLogsDao(db),
        authContextDao: AuthContextDao(db),
      ),
    );
  });

  tearDown(() async {
    if (sl.isRegistered<AuditLogService>()) sl.unregister<AuditLogService>();
    await db.close();
  });

  Future<String> createDraft() => repo.createPurchaseOrder(
    businessId: 'b1',
    createdById: 'u1',
    createdByName: 'Owner',
    lines: const [],
  );

  test('approver approves a draft directly (no submit step)', () async {
    final id = await createDraft();

    await repo.approvePurchaseOrder(
      id: id,
      approvedById: 'mgr',
      approvedByName: 'Manager',
    );

    final row = await poDao.getById(id);
    expect(row, isNotNull);
    expect(PoStatus.fromString(row!.status), PoStatus.approved);
    expect(row.approvedByName, 'Manager');
    expect(row.submittedAt, isNull, reason: 'never went through submit');
  });

  test('submit then approve still works', () async {
    final id = await createDraft();

    await repo.submitPurchaseOrder(id);
    var row = await poDao.getById(id);
    expect(PoStatus.fromString(row!.status), PoStatus.submitted);
    expect(row.submittedAt, isNotNull);

    await repo.approvePurchaseOrder(
      id: id,
      approvedById: 'mgr',
      approvedByName: 'Manager',
    );
    row = await poDao.getById(id);
    expect(PoStatus.fromString(row!.status), PoStatus.approved);
  });

  test('re-approving an already-approved PO is rejected', () async {
    final id = await createDraft();
    await repo.approvePurchaseOrder(
      id: id,
      approvedById: 'mgr',
      approvedByName: 'Manager',
    );

    expect(
      () => repo.approvePurchaseOrder(
        id: id,
        approvedById: 'mgr',
        approvedByName: 'Manager',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
