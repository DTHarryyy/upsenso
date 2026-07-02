import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';

/// The deterministic numbers behind the insight card, gathered for one
/// business/branch/period. [InsightsGenerator] turns this into plain-language
/// [Insight]s; nothing here touches the database or the LLM, so the generator
/// stays pure and unit-testable.
class InsightsMetrics {
  /// Sales this period vs the equal-length preceding period.
  final SalesTrendResult salesTrend;

  /// Total approved expenses this period.
  final double approvedExpenseTotal;

  /// Best-selling products this period (by sales value, highest first).
  final List<ProductSalesResult> topProducts;

  /// Products by gross margin this period (highest first).
  final List<MarginMoverResult> marginMovers;

  /// Count of tracked variants at or below their low-stock threshold.
  final int lowStockCount;

  const InsightsMetrics({
    required this.salesTrend,
    required this.approvedExpenseTotal,
    required this.topProducts,
    required this.marginMovers,
    required this.lowStockCount,
  });
}
