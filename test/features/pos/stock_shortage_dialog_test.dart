import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/inventory/domain/entities/stock_shortage.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/pos/presentation/widgets/stock_shortage_dialog.dart';

void main() {
  final item = CartItem(
    variantId: 'variant-1',
    name: 'Coffee',
    variant: 'Large',
    unitPrice: 100,
  )..qty = 3;

  Future<bool> openDialog(WidgetTester tester, String action) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showStockShortageDialog(
                context: context,
                items: [item],
                shortages: const [
                  StockShortage(
                    variantId: 'variant-1',
                    available: 0,
                    requested: 3,
                  ),
                ],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Not enough stock'), findsOneWidget);
    expect(find.text('Coffee (Large)'), findsOneWidget);
    expect(find.text('Requested 3 · Available 0'), findsOneWidget);
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
    return result!;
  }

  testWidgets('cancel returns false', (tester) async {
    expect(await openDialog(tester, 'Cancel'), isFalse);
  });

  testWidgets('proceed anyway returns true', (tester) async {
    expect(await openDialog(tester, 'Proceed Anyway'), isTrue);
  });
}
