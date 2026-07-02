import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';
import 'package:pos/features/insights/domain/insight.dart';
import 'package:pos/features/insights/domain/insights_generator.dart';
import 'package:pos/features/insights/domain/insights_metrics.dart';

// Pure-logic coverage for deterministic insight phrasing, metrics, and thresholds.
void main() {
  const gen = InsightsGenerator();

  InsightsMetrics metrics({
    SalesTrendResult salesTrend = const SalesTrendResult(current: 0, previous: 0),
    double expenses = 0,
    List<ProductSalesResult> topProducts = const [],
    List<MarginMoverResult> marginMovers = const [],
    int lowStockCount = 0,
  }) {
    return InsightsMetrics(
      salesTrend: salesTrend,
      approvedExpenseTotal: expenses,
      topProducts: topProducts,
      marginMovers: marginMovers,
      lowStockCount: lowStockCount,
    );
  }

  Insight? salesInsight(List<Insight> all) => all
      .where((i) => i.category == InsightCategory.sales)
      .cast<Insight?>()
      .firstWhere((i) => i!.message.startsWith('Sales'), orElse: () => null);

  Insight inventory(List<Insight> all) =>
      all.firstWhere((i) => i.category == InsightCategory.inventory);

  group('InsightsGenerator sales trend', () {
    test('flags a significant rise as positive with metric', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 1500, previous: 1000),
      ));
      final s = salesInsight(out)!;
      expect(s.severity, InsightSeverity.positive);
      expect(s.metric, '+50.0%');
      expect(s.metricSubtext, 'vs last week');
    });

    test('flags a significant drop as attention with negative metric', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 800, previous: 1000),
      ));
      final s = salesInsight(out)!;
      expect(s.severity, InsightSeverity.attention);
      expect(s.metric, '-20.0%');
    });

    test('a small swing reads as about the same (neutral)', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 1050, previous: 1000),
      ));
      final s = salesInsight(out)!;
      expect(s.severity, InsightSeverity.neutral);
      expect(s.message, contains('about the same'));
    });

    test('no previous period is positive with currency metric', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 1200, previous: 0),
      ));
      final s = salesInsight(out)!;
      expect(s.severity, InsightSeverity.positive);
      // metric is the formatted currency amount, metricSubtext is 'this period'
      expect(s.metric, isNotNull);
      expect(s.metricSubtext, 'this period');
    });
  });

  group('InsightsGenerator low stock', () {
    test('zero low-stock items is positive', () {
      final out = gen.generate(metrics(lowStockCount: 0));
      expect(inventory(out).severity, InsightSeverity.positive);
    });

    test('a few low-stock items is attention with correct count', () {
      final out = gen.generate(metrics(lowStockCount: 1));
      final inv = inventory(out);
      expect(inv.severity, InsightSeverity.attention);
      expect(inv.metric, '1');
      expect(inv.message, contains('1 product running low'));
    });

    test('many low-stock items escalates to critical', () {
      final out = gen.generate(metrics(
        lowStockCount: InsightsGenerator.lowStockCriticalCount,
      ));
      expect(inventory(out).severity, InsightSeverity.critical);
    });
  });

  group('InsightsGenerator expenses', () {
    test('no expenses produces no expense insight', () {
      final out = gen.generate(metrics(expenses: 0));
      expect(out.where((i) => i.category == InsightCategory.expenses), isEmpty);
    });

    test('expenses above half of sales is flagged for attention with ratio metric', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 1000, previous: 1000),
        expenses: 600,
      ));
      final e = out.firstWhere((i) => i.category == InsightCategory.expenses);
      expect(e.severity, InsightSeverity.attention);
      expect(e.metric, '60%');
      expect(e.metricSubtext, 'of revenue');
    });

    test('modest expenses are reported neutrally', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 1000, previous: 1000),
        expenses: 100,
      ));
      final e = out.firstWhere((i) => i.category == InsightCategory.expenses);
      expect(e.severity, InsightSeverity.neutral);
    });
  });

  group('InsightsGenerator margin + top product', () {
    test('reports the highest-margin product with percent metric', () {
      final out = gen.generate(metrics(
        marginMovers: const [
          MarginMoverResult(productName: 'Latte', revenue: 500, cost: 200),
        ],
      ));
      final m = out.firstWhere((i) => i.category == InsightCategory.margin);
      expect(m.severity, InsightSeverity.positive);
      expect(m.message, 'Latte');
      expect(m.metric, '60.0%');
      expect(m.metricSubtext, 'gross margin');
    });

    test('best seller shows product name as message and revenue as metric', () {
      final out = gen.generate(metrics(
        topProducts: const [
          ProductSalesResult(productName: 'Espresso', total: 900, quantity: 30),
        ],
      ));
      final top = out.firstWhere((i) =>
          i.category == InsightCategory.sales &&
          i.categoryLabel == 'TOP SELLER');
      expect(top.message, 'Espresso');
      expect(top.metric, isNotNull);
    });
  });

  group('InsightsGenerator ordering', () {
    test('most urgent insight is first', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 800, previous: 1000),
        lowStockCount: InsightsGenerator.lowStockCriticalCount,
      ));
      expect(out.first.severity, InsightSeverity.critical);
    });
  });
}
