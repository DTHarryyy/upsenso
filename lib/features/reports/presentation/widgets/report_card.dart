// Shared currency / percentage / chart-axis formatters for the reports feature.
// The reusable card widgets now live in lib/core/widgets (ReportSection,
// AppStatCard, AppDataTable) — this file is formatters only.

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

/// Display label for a period-over-period change. Percentage change from a
/// zero baseline is mathematically undefined — [pctChange] reports a flat
/// 100 for it (so colour/arrow logic still reads "positive"), but showing
/// "+100.0%" for $1 and for $1,000,000 of new revenue is misleading, so the
/// label says "New" instead of a fabricated percentage.
String fmtPctChange(double current, double prev) {
  if (prev == 0 && current > 0) return 'New';
  return fmtPct(pctChange(current, prev));
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
