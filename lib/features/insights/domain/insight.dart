/// A single insight shown on the dashboard card (M2).
///
/// Produced deterministically by [InsightsGenerator] from computed metrics.
/// All display-ready fields are pre-formatted — the card widget just renders
/// them without formatting logic.
library;

enum InsightCategory { sales, expenses, margin, inventory }

/// How much attention the insight deserves. [priority] drives ordering:
/// lower = surfaced first (most urgent at the top of the card).
enum InsightSeverity {
  critical(0),
  attention(1),
  positive(2),
  neutral(3);

  const InsightSeverity(this.priority);
  final int priority;
}

class Insight {
  final InsightCategory category;
  final InsightSeverity severity;

  /// Short all-caps label shown above the message, e.g. "REVENUE TREND".
  final String categoryLabel;

  /// Main message — one short sentence, display-ready.
  final String message;

  /// Optional large metric shown on the right, e.g. "+23%" or "3".
  final String? metric;

  /// Optional small descriptor under the metric, e.g. "vs last period".
  final String? metricSubtext;

  const Insight({
    required this.category,
    required this.severity,
    required this.categoryLabel,
    required this.message,
    this.metric,
    this.metricSubtext,
  });

  @override
  bool operator ==(Object other) =>
      other is Insight &&
      other.category == category &&
      other.severity == severity &&
      other.categoryLabel == categoryLabel &&
      other.message == message &&
      other.metric == metric &&
      other.metricSubtext == metricSubtext;

  @override
  int get hashCode =>
      Object.hash(category, severity, categoryLabel, message, metric, metricSubtext);

  @override
  String toString() =>
      'Insight($severity, $category, "$message", metric: $metric)';
}
