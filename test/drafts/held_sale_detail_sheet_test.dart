import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale_item.dart';
import 'package:pos/features/drafts/presentation/widgets/held_sale_detail_sheet.dart';

void main() {
  final now = DateTime(2026, 6, 11, 14, 30);
  final draft = DraftSale(
    id: 'd1',
    label: 'Table 5',
    subtotal: 40,
    taxAmount: 0,
    discountAmount: 0,
    totalAmount: 40,
    itemCount: 2,
    cashierId: 'c1',
    createdAt: now,
    updatedAt: now,
  );
  const items = [
    DraftSaleItem(
      variantId: 'v1',
      productName: 'Coke',
      variantName: '500ml',
      unitPrice: 20,
      qty: 2,
      lineTotal: 40,
      lineTax: 0,
    ),
  ];

  Future<void> pumpSheet(
    WidgetTester tester, {
    required VoidCallback onResume,
    required VoidCallback onFinish,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showHeldSaleDetailSheet(
                ctx,
                draft: draft,
                items: items,
                onResume: onResume,
                onFinish: onFinish,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders label, item and total', (tester) async {
    await pumpSheet(tester, onResume: () {}, onFinish: () {});

    expect(find.text('Table 5'), findsOneWidget);
    expect(find.text('Coke'), findsOneWidget);
    expect(find.text('Finish Sale'), findsOneWidget);
    expect(find.text('Resume in POS'), findsOneWidget);
  });

  testWidgets('Finish Sale closes the sheet and fires onFinish', (tester) async {
    var finished = false;
    await pumpSheet(tester, onResume: () {}, onFinish: () => finished = true);

    await tester.tap(find.text('Finish Sale'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(find.text('Coke'), findsNothing); // sheet dismissed
  });

  testWidgets('Resume in POS fires onResume', (tester) async {
    var resumed = false;
    await pumpSheet(tester, onResume: () => resumed = true, onFinish: () {});

    await tester.tap(find.text('Resume in POS'));
    await tester.pumpAndSettle();

    expect(resumed, isTrue);
  });
}
