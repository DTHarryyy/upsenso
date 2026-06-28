import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/refunds_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/services/refund_service.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockTransactionsDao extends Mock implements TransactionsDao {}

class MockRefundsDao extends Mock implements RefundsDao {}

class MockInventoryRepository extends Mock implements IInventoryRepository {}

class MockPermissionService extends Mock implements PermissionService {}

class MockAuditLogService extends Mock implements AuditLogService {}

void main() {
  late MockAppDatabase db;
  late MockTransactionsDao transactionsDao;
  late MockRefundsDao refundsDao;
  late MockInventoryRepository inventoryRepository;
  late MockPermissionService permissionService;
  late MockAuditLogService auditLogService;
  late RefundService service;

  setUpAll(() {
    registerFallbackValue(const RefundsTableCompanion());
    registerFallbackValue(<RefundItemsTableCompanion>[]);
  });

  setUp(() {
    db = MockAppDatabase();
    transactionsDao = MockTransactionsDao();
    refundsDao = MockRefundsDao();
    inventoryRepository = MockInventoryRepository();
    permissionService = MockPermissionService();
    auditLogService = MockAuditLogService();

    service = RefundService(
      db: db,
      transactionsDao: transactionsDao,
      refundsDao: refundsDao,
      inventoryRepository: inventoryRepository,
      permissionService: permissionService,
      auditLogService: auditLogService,
    );
  });

  // refund() checks permission, then input validity, BEFORE opening the DB
  // transaction — so both guards are fully testable without touching Drift.
  group('refund() — pre-transaction guards', () {
    test(
      'throws RefundPermissionDeniedException and never reads the sale '
      'when pos.refund_sale is not held',
      () async {
        when(
          () => permissionService.hasPermission(AppPermission.refundSale),
        ).thenReturn(false);

        await expectLater(
          service.refund(
            transactionId: 'tx1',
            lines: const [(transactionItemId: 'i1', qty: 1, restock: true)],
            businessId: 'biz1',
            refundedBy: 'user1',
          ),
          throwsA(isA<RefundPermissionDeniedException>()),
        );

        verifyNever(() => transactionsDao.getById(any()));
        verifyNever(() => refundsDao.insertRefund(any(), any()));
      },
    );

    test(
      'throws RefundValidationException and never reads the sale '
      'when every line has qty <= 0',
      () async {
        when(
          () => permissionService.hasPermission(AppPermission.refundSale),
        ).thenReturn(true);

        await expectLater(
          service.refund(
            transactionId: 'tx1',
            lines: const [(transactionItemId: 'i1', qty: 0, restock: true)],
            businessId: 'biz1',
            refundedBy: 'user1',
          ),
          throwsA(isA<RefundValidationException>()),
        );

        verifyNever(() => transactionsDao.getById(any()));
        verifyNever(() => refundsDao.insertRefund(any(), any()));
      },
    );
  });
}
