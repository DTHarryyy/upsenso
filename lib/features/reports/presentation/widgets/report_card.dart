import 'package:pos/core/widgets/stat_card.dart';

// Re-export core widgets under legacy report names for backward compatibility.
typedef ReportCard = AppCard;
typedef ReportStatCard = AppStatCard;
typedef ReportStatCardsRow = StatCardsRow;

// ─── Report formatters ────────────────────────────────────────────────────────

String fmtCurrency(double v) {
  if (v >= 1000000) return '₱${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(1)}k';
  return '₱${v.toStringAsFixed(0)}';
}

String fmtPct(double pct) {
  final sign = pct >= 0 ? '+' : '';
  return '$sign${pct.toStringAsFixed(1)}%';
}

double pctChange(double current, double prev) {
  if (prev == 0) return current > 0 ? 100 : 0;
  return (current - prev) / prev * 100;
}

double chartMaxY(List<double> values) {
  if (values.isEmpty) return 1000;
  final max = values.reduce((a, b) => a > b ? a : b);
  if (max == 0) return 1000;
  final step = (max / 4).ceilToDouble();
  final rounded = (step / 100).ceil() * 100.0;
  return rounded * 4;
}

String fmtAxisAmount(double v) {
  if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(1)}k';
  return '₱${v.toInt()}';
}
