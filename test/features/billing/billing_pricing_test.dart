import 'package:flutter_test/flutter_test.dart';

import 'package:pos/features/billing/domain/billing_models.dart';

void main() {
  // §5.1: annual = monthly × 10 (2 months free), one rule, never stored.
  group('PlanOption pricing math', () {
    PlanOption plan(double monthly) => PlanOption(
          code: 'growth',
          version: 1,
          name: 'Growth',
          priceMonthly: monthly,
          isActive: true,
          cloudEnabled: true,
        );

    test('annual is 10× monthly (2 months free)', () {
      expect(plan(199).priceAnnual, 1990);
      expect(plan(499).priceAnnual, 4990);
    });

    test('the discount is exactly 16.667%', () {
      const monthly = 499.0;
      final annual = plan(monthly).priceAnnual;
      final discount = 1 - (annual / (monthly * 12));
      expect(discount, closeTo(0.16667, 0.0001));
    });

    test('per-day framing divides the monthly price by 30', () {
      expect(plan(199).perDay, closeTo(6.63, 0.01));
      expect(plan(499).perDay, closeTo(16.63, 0.01));
    });
  });
}
