import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';

// Regression: a synced unit-product row must read back its integer quantity,
// not 0. The cloud stores quantity_decimal=0.0 for unit products (legacy push
// coerced null → 0.0); readers use `quantityDecimal ?? quantity`, so a real 0.0
// here would mask the stock and show "Out of stock" after pulling on a 2nd device.
void main() {
  late AppDatabase db;
  late InventoryLevelsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = InventoryLevelsDao(db);
  });

  tearDown(() async => db.close());

  // Mirrors the real server shape: the app populates product_variant_id and
  // leaves the legacy text variant_id null.
  Map<String, dynamic> serverRow({
    required int quantity,
    required double quantityDecimal,
  }) => {
        'product_variant_id': 'v1',
        'variant_id': null,
        'branch_id': 'b1',
        'business_id': 'biz',
        'quantity': quantity,
        'quantity_decimal': quantityDecimal,
        'low_stock_alert_override': null,
      };

  test('pulls a row keyed by product_variant_id even when variant_id is null', () async {
    await dao.upsertFromServer(serverRow(quantity: 55, quantityDecimal: 0.0));

    final level = await dao.getLevel('v1', 'b1');
    expect(level, isNotNull);
    expect(level!.variantId, 'v1');
  });

  test('unit product: server quantity_decimal=0.0 stores as null, not 0', () async {
    await dao.upsertFromServer(serverRow(quantity: 55, quantityDecimal: 0.0));

    final level = await dao.getLevel('v1', 'b1');
    expect(level, isNotNull);
    expect(level!.quantity, 55);
    expect(level.quantityDecimal, isNull); // so quantityDecimal ?? quantity → 55
  });

  test('fractional product: a real decimal value is preserved', () async {
    await dao.upsertFromServer(serverRow(quantity: 0, quantityDecimal: 2.5));

    final level = await dao.getLevel('v1', 'b1');
    expect(level!.quantityDecimal, 2.5);
  });

  // Even if a poisoned 0.0 is already sitting in the local DB (no pull yet),
  // the read helper must not let it mask the integer quantity.
  test('effectiveQuantity ignores a stored 0.0 decimal', () async {
    await dao.upsertLevel(
      variantId: 'v1',
      branchId: 'b1',
      businessId: 'biz',
      quantity: 55,
      quantityDecimal: 0.0,
    );

    final level = await dao.getLevel('v1', 'b1');
    expect(level!.effectiveQuantity, 55);
  });

  test('effectiveQuantity uses a real decimal when present', () async {
    await dao.upsertLevel(
      variantId: 'v1',
      branchId: 'b1',
      businessId: 'biz',
      quantity: 0,
      quantityDecimal: 2.5,
    );

    final level = await dao.getLevel('v1', 'b1');
    expect(level!.effectiveQuantity, 2.5);
  });
}
