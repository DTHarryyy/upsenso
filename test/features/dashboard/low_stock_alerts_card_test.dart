import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/dashboard/presentation/widgets/low_stock_alerts_card.dart';

void main() {
  const item = LowStockItem(
    productId: 'product-1',
    variantId: 'variant-1',
    displayName: 'Coffee (Large)',
    currentStock: 0,
    reorderAt: 5,
  );

  testWidgets('manage button and item row invoke their navigation callbacks', (
    tester,
  ) async {
    var manageTaps = 0;
    LowStockItem? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LowStockAlertsCard(
            items: const [item],
            onManageStock: () => manageTaps++,
            onItemTap: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Manage Stock'));
    expect(manageTaps, 1);

    await tester.tap(find.text('Coffee (Large)'));
    expect(selected?.variantId, 'variant-1');
  });
}
