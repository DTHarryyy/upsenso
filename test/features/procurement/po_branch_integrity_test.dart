import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/purchase_order_lines_dao.dart';
import 'package:pos/core/database/daos/purchase_orders_dao.dart';
import 'package:pos/core/database/daos/po_number_sequences_dao.dart';
import 'package:pos/core/database/daos/procurement_settings_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/database/daos/suppliers_dao.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/services/po_number_service.dart';
import 'package:pos/core/services/stock_movement_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/procurement/data/datasources/procurement_remote_ds.dart';
import 'package:pos/features/procurement/data/procurement_repository.dart';
import 'package:pos/features/procurement/domain/entities/po_input.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';
import 'package:pos/features/procurement/presentation/cubit/po_cubit.dart';

/// Captures the branchId the cubit forwards to the repository on create.
class _CapturingRepo implements IProcurementRepository {
  String? capturedBranchId;
  bool branchWasProvided = false;

  @override
  Future<String> createPurchaseOrder({
    required String businessId,
    String? branchId,
    String? supplierId,
    String? supplierName,
    String? notes,
    DateTime? expectedDelivery,
    double discount = 0,
    double shipping = 0,
    required String createdById,
    required String createdByName,
    required List<PoLineInput> lines,
  }) async {
    branchWasProvided = true;
    capturedBranchId = branchId;
    return 'po-1';
  }

  @override
  Stream<List<PurchaseOrder>> watchPurchaseOrders(String businessId) =>
      Stream.value(const []);

  @override
  Future<List<Supplier>> getSuppliers(String businessId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

Future<PermissionService> _ownerPermissions(
  AppDatabase db,
  String businessId,
) async {
  final perms = PermissionService(
    authContextDao: db.authContextDao,
    activeBusinessContext: ActiveBusinessContext(),
    auditLogService: AuditLogService(
      dao: db.auditLogsDao,
      authContextDao: db.authContextDao,
      activeBusinessContext: ActiveBusinessContext(),
    ),
    permissionsDao: db.employeePermissionsDao,
    permissionRemoteDs: PermissionRemoteDs(
      SupabaseClient('http://localhost', 'test-anon-key'),
    ),
    businessModulesDao: db.businessModulesDao,
  );
  perms.setRole('owner');
  // The procurement module gate fails closed until module state loads — enable
  // it so the cubit's create guard reflects the owner's real grant.
  await db.businessModulesDao.saveModules(businessId, {'procurement': true});
  await perms.loadEnabledModules(businessId);
  return perms;
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('PoCubit tags a new PO with its operating branch when none is passed',
      () async {
    final repo = _CapturingRepo();
    final cubit = PoCubit(
      repository: repo,
      permissions: await _ownerPermissions(db, 'biz-1'),
      businessId: 'biz-1',
      userId: 'user-1',
      userName: 'Tester',
      branchId: 'branch-9',
    );

    await cubit.createPurchaseOrder(
      lines: const [
        PoLineInput(
          productId: 'p1',
          variantId: 'v1',
          productName: 'Item',
          variantName: 'Default',
          quantityOrdered: 1,
          unitCost: 10,
        ),
      ],
    );

    expect(repo.branchWasProvided, isTrue);
    expect(repo.capturedBranchId, 'branch-9');
    await cubit.close();
  });

  test('receiveGoods refuses an empty branch (no orphan inventory)', () async {
    final stockMovement = StockMovementService(
      ledgerDao: StockLedgerDao(db),
      levelsDao: InventoryLevelsDao(db),
      variantsDao: ProductVariantsDao(db),
    );
    final repo = ProcurementRepository(
      suppliersDao: SuppliersDao(db),
      purchaseOrdersDao: PurchaseOrdersDao(db),
      purchaseOrderLinesDao: PurchaseOrderLinesDao(db),
      variantsDao: ProductVariantsDao(db),
      levelsDao: InventoryLevelsDao(db),
      stockMovement: stockMovement,
      poNumberService: PoNumberService(
        SupabaseClient('http://localhost', 'test-anon-key'),
        PoNumberSequencesDao(db),
      ),
      settingsDao: ProcurementSettingsDao(db),
      remoteDs: ProcurementRemoteDs(
        SupabaseClient('http://localhost', 'test-anon-key'),
      ),
    );

    await expectLater(
      repo.receiveGoods(poId: 'po-1', branchId: '   ', lines: const []),
      throwsA(isA<Exception>()),
    );
  });
}
