/// A single plain-language insight shown on the dashboard insight card (M2).
///
/// Insights are produced deterministically by [InsightsGenerator] from computed
/// metrics; the message is already phrased for display. Severity drives both the
/// ordering (most urgent first) and the card's visual treatment.
library;

/// What kind of metric an insight is about — used for the leading icon.
enum InsightCategory { sales, expenses, margin, inventory }

/// How much attention an insight deserves. [priority] orders them on the card
/// (lower = shown first), so "needs attention" always surfaces above "doing
/// well".
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

  /// Plain-language, display-ready text (already formatted with figures).
  final String message;

  const Insight({
    required this.category,
    required this.severity,
    required this.message,
  });

  @override
  bool operator ==(Object other) =>
      other is Insight &&
      other.category == category &&
      other.severity == severity &&
      other.message == message;

  @override
  int get hashCode => Object.hash(category, severity, message);

  @override
  String toString() => 'Insight($severity, $category, "$message")';
}
