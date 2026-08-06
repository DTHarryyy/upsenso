import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/services/checkout_service.dart';
import 'package:pos/core/services/invoice_number_service.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/domain/entities/stock_shortage.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';

class _MockInvoiceNumberService extends Mock implements InvoiceNumberService {}

class _MockAuditLogService extends Mock implements AuditLogService {}

class _FakeInventoryRepository implements IInventoryRepository {
  List<StockShortage> shortages = const [];
  bool deductionsRecorded = false;
  bool? allowedNegativeStock;

  @override
  Future<List<StockShortage>> checkStockAvailability({
    required List<({String variantId, double qty})> items,
    required String? branchId,
  }) async => shortages;

  @override
  Future<void> recordSaleDeductions({
    required List<({String variantId, double qty})> items,
    required String businessId,
    required String? branchId,
    required String sourceId,
    bool allowNegativeStock = false,
  }) async {
    deductionsRecorded = true;
    allowedNegativeStock = allowNegativeStock;
  }

  @override
  Stream<void> watchChanges(String businessId) => const Stream.empty();

  @override
  Future<InventoryData> load({
    required String businessId,
    String? branchId,
  }) async => InventoryData.empty;

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
  }) async {}

  @override
  Future<void> reverseSaleDeductions({
    required List<({String variantId, double qty})> items,
    required String businessId,
    required String? branchId,
    required String sourceId,
  }) async {}
}

void main() {
  late AppDatabase db;
  late _FakeInventoryRepository inventory;
  late _MockInvoiceNumberService invoiceNumbers;
  late _MockAuditLogService auditLog;
  late CheckoutService service;
  Map<String, dynamic>? auditMetadata;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    inventory = _FakeInventoryRepository();
    invoiceNumbers = _MockInvoiceNumberService();
    auditLog = _MockAuditLogService();
    auditMetadata = null;
    when(
      () => invoiceNumbers.claimNext('business-1'),
    ).thenAnswer((_) async => 'INV-000001');
    when(
      () => auditLog.log(
        actionType: AuditLogActionType.saleCreated,
        entityType: 'transaction',
        entityId: 'transaction-1',
        description: any(named: 'description'),
        metadata: any(named: 'metadata'),
        businessId: 'business-1',
        branchId: 'branch-1',
        userId: 'cashier-1',
      ),
    ).thenAnswer((invocation) async {
      auditMetadata =
          invocation.namedArguments[#metadata] as Map<String, dynamic>;
    });
    service = CheckoutService(
      db: db,
      transactionsDao: TransactionsDao(db),
      inventoryRepository: inventory,
      invoiceNumberService: invoiceNumbers,
      auditLogService: auditLog,
    );
  });

  tearDown(() => db.close());

  TransactionsTableCompanion transaction() => TransactionsTableCompanion.insert(
    id: 'transaction-1',
    cashierId: 'cashier-1',
    businessId: const Value('business-1'),
    branchId: const Value('branch-1'),
    totalAmount: 100,
    taxAmount: 0,
    subtotal: 100,
    itemCount: 1,
  );

  List<TransactionItemsTableCompanion> items() => [
    TransactionItemsTableCompanion.insert(
      id: 'item-1',
      transactionId: 'transaction-1',
      variantId: 'variant-1',
      productName: 'Coffee',
      variantName: 'Default',
      unitPrice: 100,
      qty: 2,
      lineTotal: 200,
      lineTax: 0,
    ),
  ];

  test(
    'shortage without approval leaves sale and deductions untouched',
    () async {
      inventory.shortages = const [
        StockShortage(variantId: 'variant-1', available: 0, requested: 2),
      ];

      await expectLater(
        service.completeSale(
          transaction: transaction(),
          items: items(),
          deductions: const [(variantId: 'variant-1', qty: 2)],
          businessId: 'business-1',
          branchId: 'branch-1',
          transactionId: 'transaction-1',
        ),
        throwsA(isA<InsufficientStockException>()),
      );

      expect(await db.select(db.transactionsTable).get(), isEmpty);
      expect(inventory.deductionsRecorded, isFalse);
    },
  );

  test(
    'approved shortage records sale, negative deduction, and audit detail',
    () async {
      inventory.shortages = const [
        StockShortage(variantId: 'variant-1', available: 0, requested: 2),
      ];

      await service.completeSale(
        transaction: transaction(),
        items: items(),
        deductions: const [(variantId: 'variant-1', qty: 2)],
        businessId: 'business-1',
        branchId: 'branch-1',
        transactionId: 'transaction-1',
        allowOversell: true,
      );

      expect(await db.select(db.transactionsTable).get(), hasLength(1));
      expect(inventory.deductionsRecorded, isTrue);
      expect(inventory.allowedNegativeStock, isTrue);
      expect(auditMetadata?['stock_override'], isTrue);
      expect(auditMetadata?['stock_shortages'], [
        {'variant_id': 'variant-1', 'available': 0.0, 'requested': 2.0},
      ]);
    },
  );
}
