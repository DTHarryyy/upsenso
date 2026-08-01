/// Shared short date format for billing rows (device "last seen", payment date).
String formatBillingDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Plan prices are whole pesos, so they render without decimals — `₱4,990`, not
/// `₱4,990.00`, which reads as a bill rather than a price tag.
String formatPlanPrice(double v) {
  final s = v.round().abs().toString();
  final buf = StringBuffer(v < 0 ? '-' : '');
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
