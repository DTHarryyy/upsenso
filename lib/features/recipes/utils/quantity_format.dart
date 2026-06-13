/// Formats a stock quantity for display: whole numbers drop the decimal,
/// fractional amounts keep two places. Shared across the ingredient UI so the
/// hero number and ledger rows always read the same way.
String formatQuantity(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
