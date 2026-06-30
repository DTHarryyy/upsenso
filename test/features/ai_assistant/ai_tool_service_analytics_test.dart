import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';

// Pure-logic coverage for the M2 insight primitives: the previous-period window
// math (the bug-prone part of trend comparisons) and the SalesTrendResult
// derivations. The SQL methods themselves are exercised during device QA.
void main() {
  group('AiToolService.previousPeriod', () {
    test('returns the equal-length window immediately before the range', () {
      final start = DateTime(2026, 6, 8);
      final end = DateTime(2026, 6, 15); // 7-day window
      final prev = AiToolService.previousPeriod(start: start, end: end);

      expect(prev.end, start);
      expect(prev.start, DateTime(2026, 6, 1));
    });

    test('previous window has the same duration as the current one', () {
      final start = DateTime(2026, 6, 1, 9, 0);
      final end = DateTime(2026, 6, 1, 17, 30); // 8h30m
      final prev = AiToolService.previousPeriod(start: start, end: end);

      expect(end.difference(start), prev.end.difference(prev.start));
    });

    test('handles a single-day window', () {
      final start = DateTime(2026, 6, 15);
      final end = DateTime(2026, 6, 16);
      final prev = AiToolService.previousPeriod(start: start, end: end);

      expect(prev.start, DateTime(2026, 6, 14));
      expect(prev.end, DateTime(2026, 6, 15));
    });

    test('previous window does not overlap the current window', () {
      final start = DateTime(2026, 6, 8);
      final end = DateTime(2026, 6, 15);
      final prev = AiToolService.previousPeriod(start: start, end: end);

      expect(prev.end.isAfter(start), isFalse);
    });
  });

  group('SalesTrendResult', () {
    test('delta is current minus previous', () {
      const r = SalesTrendResult(current: 1500, previous: 1000);
      expect(r.delta, 500);
    });

    test('deltaPercent computes percentage change', () {
      const r = SalesTrendResult(current: 1500, previous: 1000);
      expect(r.deltaPercent, 50);
    });

    test('deltaPercent is null when previous is zero (undefined base)', () {
      const r = SalesTrendResult(current: 1500, previous: 0);
      expect(r.deltaPercent, isNull);
    });

    test('isUp / isDown reflect direction', () {
      const up = SalesTrendResult(current: 1200, previous: 1000);
      const down = SalesTrendResult(current: 800, previous: 1000);
      const flat = SalesTrendResult(current: 1000, previous: 1000);

      expect(up.isUp, isTrue);
      expect(up.isDown, isFalse);
      expect(down.isDown, isTrue);
      expect(flat.isUp, isFalse);
      expect(flat.isDown, isFalse);
    });

    test('negative delta and percentage on a drop', () {
      const r = SalesTrendResult(current: 800, previous: 1000);
      expect(r.delta, -200);
      expect(r.deltaPercent, -20);
    });
  });

  group('MarginMoverResult', () {
    test('margin is revenue minus cost', () {
      const r = MarginMoverResult(productName: 'Latte', revenue: 500, cost: 200);
      expect(r.margin, 300);
    });

    test('marginPercent is margin over revenue', () {
      const r = MarginMoverResult(productName: 'Latte', revenue: 500, cost: 200);
      expect(r.marginPercent, 60);
    });

    test('marginPercent is null when revenue is zero (undefined base)', () {
      const r = MarginMoverResult(productName: 'Latte', revenue: 0, cost: 0);
      expect(r.marginPercent, isNull);
    });

    test('negative margin when cost exceeds revenue (loss leader)', () {
      const r = MarginMoverResult(productName: 'Latte', revenue: 200, cost: 250);
      expect(r.margin, -50);
      expect(r.marginPercent, -25);
    });
  });
}
