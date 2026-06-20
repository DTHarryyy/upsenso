import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/services/checkout_service.dart';
import 'package:pos/core/services/invoice_number_service.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The AI sale path used to insert a transaction directly without claiming an
/// invoice number and would accept a null business (a tenant leak). It now goes
/// through CheckoutService like POS checkout. These tests pin both behaviours.
void main() {
  late AppDatabase db;
  late _FakeInventoryRepository inventory;
  late AiToolService toolService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    inventory = _FakeInventoryRepository();
    // Offline connectivity forces the deterministic local-counter invoice path
    // so the test never touches the network.
    final invoiceService = InvoiceNumberService(
      SupabaseClient('http://localhost', 'test-anon-key'),
      db.invoiceSequencesDao,
      ConnectivityService(_OfflineConnectivity()),
    );
    final checkout = CheckoutService(
      db: db,
      transactionsDao: db.transactionsDao,
      inventoryRepository: inventory,
      invoiceNumberService: invoiceService,
    );
    toolService = AiToolService(
      productsDao: db.productsDao,
      variantsDao: db.productVariantsDao,
      checkoutService: checkout,
      db: db,
    );
  });

  tearDown(() => db.close());

  List<TransactionLineItem> oneLine() => const [
        TransactionLineItem(
          variantId: 'variant-1',
          productName: 'Coffee',
          variantName: 'Large',
          unitPrice: 50.0,
          taxRate: 0,
          quantity: 1,
        ),
      ];

  test('refuses a sale with no active business', () async {
    expect(
      () => toolService.createTransaction(
        cashierId: 'cashier-1',
        businessId: null,
        branchId: null,
        lineItems: oneLine(),
      ),
      throwsA(isA<AiSaleException>()),
    );

    final all = await db.transactionsDao.watchTransactions().first;
    expect(all, isEmpty, reason: 'no row should be written when guard trips');
  });

  test('persists business_id and a claimed invoice number on success', () async {
    final txId = await toolService.createTransaction(
      cashierId: 'cashier-1',
      businessId: 'biz-1',
      branchId: null,
      lineItems: oneLine(),
    );

    final row = await db.transactionsDao.getById(txId);
    expect(row, isNotNull);
    expect(row!.businessId, 'biz-1');
    expect(row.invoiceNumber, startsWith('INV-'));
    expect(inventory.deductionCalls, 1, reason: 'stock must be deducted once');
  });
}

/// Minimal fake — only the two methods CheckoutService.completeSale touches are
/// implemented; the rest are never reached on this path.
class _FakeInventoryRepository implements IInventoryRepository {
  int deductionCalls = 0;

  @override
  Future<void> recordSaleDeductions({
    required List<({String variantId, double qty})> items,
    required String businessId,
    required String? branchId,
  }) async {
    deductionCalls++;
  }

  @override
  Future<List<({String variantId, double available, double requested})>>
      checkStockAvailability({
    required List<({String variantId, double qty})> items,
    required String? branchId,
  }) async =>
          const [];

  @override
  Future<void> reverseSaleDeductions({
    required List<({String variantId, double qty})> items,
    required String businessId,
    required String? branchId,
    required String sourceId,
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

/// Reports no link type so ConnectivityService.isConnected is false.
class _OfflineConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.none];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}
