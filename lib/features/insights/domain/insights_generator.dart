import 'package:pos/core/utils/formatters.dart';
import 'package:pos/features/insights/domain/insight.dart';
import 'package:pos/features/insights/domain/insights_metrics.dart';

/// Turns computed [InsightsMetrics] into a short ordered list of [Insight]s.
///
/// Pure and deterministic: same metrics → same output, no I/O, no LLM.
class InsightsGenerator {
  const InsightsGenerator();

  static const double significantSalesChangePct = 10.0;
  static const int lowStockCriticalCount = 5;
  static const double expenseToSalesAttentionRatio = 0.5;

  List<Insight> generate(InsightsMetrics m) {
    final insights = <Insight>[
      _salesTrend(m),
      ?_topProduct(m),
      ?_margin(m),
      _lowStock(m),
      ?_expenses(m),
    ];

    insights.sort((a, b) => a.severity.priority.compareTo(b.severity.priority));
    return insights;
  }

  Insight _salesTrend(InsightsMetrics m) {
    final t = m.salesTrend;
    final cur = AppFormatters.currency(t.current);

    if (t.deltaPercent == null) {
      return Insight(
        category: InsightCategory.sales,
        severity: t.current > 0 ? InsightSeverity.positive : InsightSeverity.neutral,
        categoryLabel: 'REVENUE',
        message: t.current > 0
            ? 'Sales so far this period'
            : 'No sales recorded yet',
        metric: t.current > 0 ? cur : null,
        metricSubtext: t.current > 0 ? 'this period' : null,
      );
    }

    final pct = t.deltaPercent!;
    final magnitude = pct.abs().toStringAsFixed(1);

    if (pct.abs() < significantSalesChangePct) {
      return Insight(
        category: InsightCategory.sales,
        severity: InsightSeverity.neutral,
        categoryLabel: 'REVENUE TREND',
        message: 'Sales are about the same as last period',
        metric: cur,
        metricSubtext: 'this period',
      );
    }

    if (t.isUp) {
      return Insight(
        category: InsightCategory.sales,
        severity: InsightSeverity.positive,
        categoryLabel: 'REVENUE TREND',
        message: 'Sales are up vs last week',
        metric: '+$magnitude%',
        metricSubtext: 'vs last week',
      );
    }

    return Insight(
      category: InsightCategory.sales,
      severity: InsightSeverity.attention,
      categoryLabel: 'REVENUE TREND',
      message: 'Sales are down vs last week',
      metric: '-$magnitude%',
      metricSubtext: 'vs last week',
    );
  }

  Insight? _topProduct(InsightsMetrics m) {
    if (m.topProducts.isEmpty) return null;
    final top = m.topProducts.first;
    if (top.total <= 0) return null;
    return Insight(
      category: InsightCategory.sales,
      severity: InsightSeverity.neutral,
      categoryLabel: 'TOP SELLER',
      message: top.productName,
      metric: AppFormatters.currency(top.total),
      metricSubtext: 'in sales',
    );
  }

  Insight? _margin(InsightsMetrics m) {
    if (m.marginMovers.isEmpty) return null;
    final best = m.marginMovers.first;
    final pct = best.marginPercent;
    if (pct == null) return null;
    return Insight(
      category: InsightCategory.margin,
      severity: InsightSeverity.positive,
      categoryLabel: 'TOP MARGIN',
      message: best.productName,
      metric: '${pct.toStringAsFixed(1)}%',
      metricSubtext: 'gross margin',
    );
  }

  Insight _lowStock(InsightsMetrics m) {
    final n = m.lowStockCount;
    if (n <= 0) {
      return const Insight(
        category: InsightCategory.inventory,
        severity: InsightSeverity.positive,
        categoryLabel: 'INVENTORY',
        message: 'All tracked stock is above its threshold',
        metric: null,
        metricSubtext: null,
      );
    }
    final noun = n == 1 ? 'product' : 'products';
    if (n >= lowStockCriticalCount) {
      return Insight(
        category: InsightCategory.inventory,
        severity: InsightSeverity.critical,
        categoryLabel: 'LOW STOCK',
        message: '$n $noun need restocking soon',
        metric: '$n',
        metricSubtext: 'items low',
      );
    }
    return Insight(
      category: InsightCategory.inventory,
      severity: InsightSeverity.attention,
      categoryLabel: 'LOW STOCK',
      message: '$n $noun running low on stock',
      metric: '$n',
      metricSubtext: 'items low',
    );
  }

  Insight? _expenses(InsightsMetrics m) {
    final expenses = m.approvedExpenseTotal;
    if (expenses <= 0) return null;
    final amount = AppFormatters.currency(expenses);
    final sales = m.salesTrend.current;
    if (sales > 0 && expenses / sales >= expenseToSalesAttentionRatio) {
      final share = (expenses / sales * 100).toStringAsFixed(0);
      return Insight(
        category: InsightCategory.expenses,
        severity: InsightSeverity.attention,
        categoryLabel: 'EXPENSES',
        message: 'Approved expenses are high vs sales',
        metric: '$share%',
        metricSubtext: 'of revenue',
      );
    }
    return Insight(
      category: InsightCategory.expenses,
      severity: InsightSeverity.neutral,
      categoryLabel: 'EXPENSES',
      message: 'Approved expenses this period',
      metric: amount,
      metricSubtext: 'approved',
    );
  }
}
