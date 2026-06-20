/// Formats a stock quantity for display. Stock is stored as a single decimal
/// (unit and fractional products share one column), so whole values render
/// without a trailing ".0" while fractional values keep their decimals.
String qtyLabel(num q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  // Trim trailing zeros (e.g. 1.50 -> 1.5) without forcing a fixed precision.
  return q.toString();
}
