import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/services/refund_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';

/// Covers the plan's verification checklist: full refund, partial refund, a
/// second partial that completes a line, over-refund rejection, and
/// permission-denied rejection. Mirrors the AppDatabase.forTesting pattern
/// already used for CheckoutService-style atomic-transaction tests.
void main() {
  late AppDatabase db;
  late _FakeInventoryRepository inventory;
  late PermissionService permissionService;
  late RefundService refundService;

  const businessId = 'biz-1';
  const branchId = 'branch-1';
  const txId = 'tx-1';
  const item1Id = 'item-1'; // 2 units @ 100 each = 200
  const item2Id = 'item-2'; // 1 unit @ 50 = 50

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    inventory = _FakeInventoryRepository();
    permissionService = PermissionService(
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
    permissionService.setRole('owner'); // grants pos.refund_sale

    refundService = RefundService(
      db: db,
      transactionsDao: db.transactionsDao,
      refundsDao: db.refundsDao,
      inventoryRepository: inventory,
      permissionService: permissionService,
      auditLogService: AuditLogService(
        dao: db.auditLogsDao,
        authContextDao: db.authContextDao,
        activeBusinessContext: ActiveBusinessContext(),
      ),
    );

    await db.transactionsDao.insertTransaction(
      TransactionsTableCompanion.insert(
        id: txId,
        cashierId: 'cashier-1',
        businessId: const Value(businessId),
        branchId: const Value(branchId),
        totalAmount: 250.0,
        taxAmount: 0.0,
        subtotal: 250.0,
        itemCount: 2,
      ),
      [
        TransactionItemsTableCompanion.insert(
          id: item1Id,
          transactionId: txId,
          variantId: 'variant-1',
          productName: 'Coffee',
          variantName: 'Large',
          unitPrice: 100.0,
          qty: 2,
          lineTotal: 200.0,
          lineTax: 0.0,
        ),
        TransactionItemsTableCompanion.insert(
          id: item2Id,
          transactionId: txId,
          variantId: 'variant-2',
          productName: 'Tea',
          variantName: 'Default',
          unitPrice: 50.0,
          qty: 1,
          lineTotal: 50.0,
          lineTax: 0.0,
        ),
      ],
    );
  });

  tearDown(() => db.close());

  test('full refund of every line marks the sale refunded and restocks all items', () async {
    await refundService.refund(
      transactionId: txId,
      lines: const [
        (transactionItemId: item1Id, qty: 2.0, restock: true),
        (transactionItemId: item2Id, qty: 1.0, restock: true),
      ],
      businessId: businessId,
      refundedBy: 'user-1',
    );

    final tx = await db.transactionsDao.getById(txId);
    expect(tx!.status, 'refunded');

    final refunds = await db.refundsDao.getByTransactionId(txId);
    expect(refunds, hasLength(1));
    expect(refunds.first.totalAmount, 250.0);
    expect(refunds.first.branchId, branchId);

    expect(inventory.reversedItems, hasLength(2));
    expect(
      inventory.reversedItems.map((i) => i.variantId),
      containsAll(['variant-1', 'variant-2']),
    );
  });

  test('partial refund of one line marks the sale partially_refunded', () async {
    await refundService.refund(
      transactionId: txId,
      lines: const [(transactionItemId: item1Id, qty: 1.0, restock: true)],
      businessId: businessId,
      refundedBy: 'user-1',
    );

    final tx = await db.transactionsDao.getById(txId);
    expect(tx!.status, 'partially_refunded');

    final refunds = await db.refundsDao.getByTransactionId(txId);
    expect(refunds.single.totalAmount, 100.0); // 1 unit @ 100

    expect(inventory.reversedItems, hasLength(1));
    expect(inventory.reversedItems.single.qty, 1.0);
  });

  test('a second partial refund that completes every line flips status to refunded', () async {
    await refundService.refund(
      transactionId: txId,
      lines: const [(transactionItemId: item1Id, qty: 1.0, restock: true)],
      businessId: businessId,
      refundedBy: 'user-1',
    );
    var tx = await db.transactionsDao.getById(txId);
    expect(tx!.status, 'partially_refunded');

    await refundService.refund(
      transactionId: txId,
      lines: const [
        (transactionItemId: item1Id, qty: 1.0, restock: true),
        (transactionItemId: item2Id, qty: 1.0, restock: true),
      ],
      businessId: businessId,
      refundedBy: 'user-1',
    );
    tx = await db.transactionsDao.getById(txId);
    expect(tx!.status, 'refunded');

    final refunds = await db.refundsDao.getByTransactionId(txId);
    expect(refunds, hasLength(2));
  });

  test('refunding more than was sold is rejected and writes nothing', () async {
    await expectLater(
      refundService.refund(
        transactionId: txId,
        lines: const [
          (transactionItemId: item1Id, qty: 3.0, restock: true), // only 2 sold
        ],
        businessId: businessId,
        refundedBy: 'user-1',
      ),
      throwsA(isA<RefundOverRefundException>()),
    );

    final tx = await db.transactionsDao.getById(txId);
    expect(tx!.status, 'completed');
    expect(await db.refundsDao.getByTransactionId(txId), isEmpty);
    expect(inventory.reversedItems, isEmpty);
  });

  test('a caller without pos.refund_sale is rejected and writes nothing', () async {
    permissionService.setRole('cashier');

    await expectLater(
      refundService.refund(
        transactionId: txId,
        lines: const [(transactionItemId: item1Id, qty: 1.0, restock: true)],
        businessId: businessId,
        refundedBy: 'user-1',
      ),
      throwsA(isA<RefundPermissionDeniedException>()),
    );

    expect(await db.refundsDao.getByTransactionId(txId), isEmpty);
    expect(inventory.reversedItems, isEmpty);
  });

  test('an empty selection is rejected', () async {
    await expectLater(
      refundService.refund(
        transactionId: txId,
        lines: const [],
        businessId: businessId,
        refundedBy: 'user-1',
      ),
      throwsA(isA<RefundValidationException>()),
    );
  });

  test('a line refunded with restock=false is recorded but never restocked', () async {
    await refundService.refund(
      transactionId: txId,
      lines: const [
        (transactionItemId: item1Id, qty: 1.0, restock: false), // damaged
        (transactionItemId: item2Id, qty: 1.0, restock: true),
      ],
      businessId: businessId,
      refundedBy: 'user-1',
    );

    // Money and status still reflect both refunded lines.
    final tx = await db.transactionsDao.getById(txId);
    expect(tx!.status, 'partially_refunded');
    final refunds = await db.refundsDao.getByTransactionId(txId);
    expect(refunds.single.totalAmount, 150.0); // 100 + 50

    // Only the restock:true line actually moved stock.
    expect(inventory.reversedItems, hasLength(1));
    expect(inventory.reversedItems.single.variantId, 'variant-2');

    // The not-restocked line is still persisted with restocked=false.
    final items = await db.refundsDao.getItemsByRefundId(refunds.single.id);
    final item1Row = items.firstWhere((i) => i.transactionItemId == item1Id);
    final item2Row = items.firstWhere((i) => i.transactionItemId == item2Id);
    expect(item1Row.restocked, isFalse);
    expect(item2Row.restocked, isTrue);
  });
}

/// Records reverseSaleDeductions calls; the other methods are never reached
/// on this path.
class _FakeInventoryRepository implements IInventoryRepository {
  final List<({String variantId, double qty})> reversedItems = [];

  @override
  Future<void> reverseSaleDeductions({
    required List<({String variantId, double qty})> items,
    required String businessId,
    required String? branchId,
    required String sourceId,
  }) async {
    reversedItems.addAll(items);
  }

  @override
  Future<void> recordSaleDeductions({
    required List<({String variantId, double qty})> items,
    required String businessId,
    required String? branchId,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<({String variantId, double available, double requested})>>
      checkStockAvailability({
    required List<({String variantId, double qty})> items,
    required String? branchId,
  }) =>
          throw UnimplementedError();

  @override
  Future<void> adjustStock({
    required String variantId,
    required String productId,
    required String businessId,
    String? branchId,
    required bool isIncoming,
    required int quantity,
    required String reason,
    String? note,
  }) =>
      throw UnimplementedError();

  @override
  Future<InventoryData> load({required String businessId, String? branchId}) =>
      throw UnimplementedError();

  @override
  Stream<void> watchChanges(String businessId) => throw UnimplementedError();
}
