import 'package:pos/core/utils/formatters.dart';
import 'package:pos/features/insights/domain/insight.dart';
import 'package:pos/features/insights/domain/insights_metrics.dart';

/// Turns computed [InsightsMetrics] into a short, ordered list of plain-language
/// [Insight]s — the "what changed / what needs attention" card content.
///
/// Pure and deterministic: same metrics in → same insights out, no I/O, no LLM.
/// This is the template phrasing that works on every platform (including web,
/// where no on-device model exists). An optional LLM rephrasing layer can wrap
/// this later without changing the numbers it decides on.
class InsightsGenerator {
  const InsightsGenerator();

  /// A sales swing smaller than this (in %) reads as "about the same" rather
  /// than a real up/down move — keeps day-to-day noise off the card.
  static const double significantSalesChangePct = 10.0;

  /// At or above this many low-stock items, the inventory insight escalates
  /// from "attention" to "critical".
  static const int lowStockCriticalCount = 5;

  /// Expenses at or above this share of sales is worth flagging.
  static const double expenseToSalesAttentionRatio = 0.5;

  List<Insight> generate(InsightsMetrics m) {
    final insights = <Insight>[
      _salesTrend(m),
      ?_topProduct(m),
      ?_margin(m),
      _lowStock(m),
      ?_expenses(m),
    ];

    // Most urgent first, stable within a severity so categories keep their
    // declaration order.
    insights.sort((a, b) => a.severity.priority.compareTo(b.severity.priority));
    return insights;
  }

  Insight _salesTrend(InsightsMetrics m) {
    final t = m.salesTrend;
    final cur = AppFormatters.currency(t.current);

    // No comparable base — phrase as "new" instead of an infinite increase.
    if (t.deltaPercent == null) {
      return Insight(
        category: InsightCategory.sales,
        severity: t.current > 0 ? InsightSeverity.positive : InsightSeverity.neutral,
        message: t.current > 0
            ? 'Sales so far this period: $cur (no comparable previous period).'
            : 'No sales recorded yet this period.',
      );
    }

    final pct = t.deltaPercent!;
    final prev = AppFormatters.currency(t.previous);
    final magnitude = pct.abs().toStringAsFixed(1);

    if (pct.abs() < significantSalesChangePct) {
      return Insight(
        category: InsightCategory.sales,
        severity: InsightSeverity.neutral,
        message: 'Sales are about the same as the previous period ($cur).',
      );
    }
    if (t.isUp) {
      return Insight(
        category: InsightCategory.sales,
        severity: InsightSeverity.positive,
        message: 'Sales are up $magnitude% vs the previous period '
            '($cur vs $prev).',
      );
    }
    return Insight(
      category: InsightCategory.sales,
      severity: InsightSeverity.attention,
      message: 'Sales are down $magnitude% vs the previous period '
          '($cur vs $prev).',
    );
  }

  Insight? _topProduct(InsightsMetrics m) {
    if (m.topProducts.isEmpty) return null;
    final top = m.topProducts.first;
    if (top.total <= 0) return null;
    return Insight(
      category: InsightCategory.sales,
      severity: InsightSeverity.neutral,
      message: 'Best seller: ${top.productName} '
          '(${AppFormatters.currency(top.total)}).',
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
      message: 'Highest margin: ${best.productName} '
          '(${pct.toStringAsFixed(1)}% margin).',
    );
  }

  Insight _lowStock(InsightsMetrics m) {
    final n = m.lowStockCount;
    if (n <= 0) {
      return const Insight(
        category: InsightCategory.inventory,
        severity: InsightSeverity.positive,
        message: 'All tracked stock is above its threshold.',
      );
    }
    final noun = n == 1 ? 'product' : 'products';
    if (n >= lowStockCriticalCount) {
      return Insight(
        category: InsightCategory.inventory,
        severity: InsightSeverity.critical,
        message: '$n $noun are low on stock — restock soon.',
      );
    }
    return Insight(
      category: InsightCategory.inventory,
      severity: InsightSeverity.attention,
      message: '$n $noun running low on stock.',
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
        message: 'Approved expenses are $share% of sales this period ($amount).',
      );
    }
    return Insight(
      category: InsightCategory.expenses,
      severity: InsightSeverity.neutral,
      message: 'Approved expenses this period: $amount.',
    );
  }
}
