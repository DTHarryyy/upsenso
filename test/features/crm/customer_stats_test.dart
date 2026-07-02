import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/crm/domain/entities/customer_purchase.dart';

void main() {
  CustomerPurchase p(double total, DateTime at) => CustomerPurchase(
        id: 't-${at.millisecondsSinceEpoch}',
        invoiceNumber: null,
        totalAmount: total,
        itemCount: 1,
        paymentMethod: 'cash',
        createdAt: at,
      );

  group('CustomerStats.fromPurchases', () {
    test('empty history yields zeroes and no last visit', () {
      const stats = CustomerStats();
      expect(stats.orderCount, 0);
      expect(stats.totalSpent, 0);
      expect(stats.lastVisitAt, isNull);
      expect(stats.averageOrderValue, 0);
    });

    test('aggregates count, total, last visit and average', () {
      final stats = CustomerStats.fromPurchases([
        p(100, DateTime(2026, 6, 1)),
        p(50, DateTime(2026, 6, 5)),
        p(150, DateTime(2026, 6, 3)),
      ]);

      expect(stats.orderCount, 3);
      expect(stats.totalSpent, 300);
      expect(stats.lastVisitAt, DateTime(2026, 6, 5));
      expect(stats.averageOrderValue, 100);
    });
  });
}
