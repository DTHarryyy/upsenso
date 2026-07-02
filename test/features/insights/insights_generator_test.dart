import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';
import 'package:pos/features/insights/domain/insight.dart';
import 'package:pos/features/insights/domain/insights_generator.dart';
import 'package:pos/features/insights/domain/insights_metrics.dart';

// Pure-logic coverage for the deterministic insight phrasing + thresholds.
// The DB gathering (InsightsRepository) is exercised in device QA.
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

  Insight? sales(List<Insight> all) =>
      all.where((i) => i.category == InsightCategory.sales).cast<Insight?>().firstWhere(
            (i) => i!.message.startsWith('Sales'),
            orElse: () => null,
          );

  Insight inventory(List<Insight> all) =>
      all.firstWhere((i) => i.category == InsightCategory.inventory);

  group('InsightsGenerator sales trend', () {
    test('flags a significant rise as positive', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 1500, previous: 1000),
      ));
      final s = sales(out)!;
      expect(s.severity, InsightSeverity.positive);
      expect(s.message, contains('up 50.0%'));
    });

    test('flags a significant drop as attention', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 800, previous: 1000),
      ));
      final s = sales(out)!;
      expect(s.severity, InsightSeverity.attention);
      expect(s.message, contains('down 20.0%'));
    });

    test('a small swing reads as about the same (neutral)', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 1050, previous: 1000),
      ));
      final s = sales(out)!;
      expect(s.severity, InsightSeverity.neutral);
      expect(s.message, contains('about the same'));
    });

    test('no comparable previous period is phrased as new, not infinite', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 1200, previous: 0),
      ));
      final s = sales(out)!;
      expect(s.severity, InsightSeverity.positive);
      expect(s.message, contains('no comparable previous period'));
    });
  });

  group('InsightsGenerator low stock', () {
    test('zero low-stock items is positive', () {
      final out = gen.generate(metrics(lowStockCount: 0));
      expect(inventory(out).severity, InsightSeverity.positive);
    });

    test('a few low-stock items is attention with correct pluralisation', () {
      final out = gen.generate(metrics(lowStockCount: 1));
      final inv = inventory(out);
      expect(inv.severity, InsightSeverity.attention);
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

    test('expenses above half of sales is flagged for attention', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 1000, previous: 1000),
        expenses: 600,
      ));
      final e = out.firstWhere((i) => i.category == InsightCategory.expenses);
      expect(e.severity, InsightSeverity.attention);
      expect(e.message, contains('60% of sales'));
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
    test('reports the highest-margin product', () {
      final out = gen.generate(metrics(
        marginMovers: const [
          MarginMoverResult(productName: 'Latte', revenue: 500, cost: 200),
        ],
      ));
      final margin = out.firstWhere((i) => i.category == InsightCategory.margin);
      expect(margin.severity, InsightSeverity.positive);
      expect(margin.message, contains('Latte'));
      expect(margin.message, contains('60.0% margin'));
    });

    test('best seller surfaces with its revenue', () {
      final out = gen.generate(metrics(
        topProducts: const [
          ProductSalesResult(productName: 'Espresso', total: 900, quantity: 30),
        ],
      ));
      final top = out.firstWhere((i) =>
          i.category == InsightCategory.sales && i.message.startsWith('Best seller'));
      expect(top.message, contains('Espresso'));
    });
  });

  group('InsightsGenerator ordering', () {
    test('most urgent insight is first', () {
      final out = gen.generate(metrics(
        salesTrend: const SalesTrendResult(current: 800, previous: 1000), // attention
        lowStockCount: InsightsGenerator.lowStockCriticalCount, // critical
      ));
      expect(out.first.severity, InsightSeverity.critical);
    });
  });
}
