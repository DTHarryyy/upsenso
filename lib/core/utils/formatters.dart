/// Centralized formatting utilities for currency, dates, and quantities.
///
/// All monetary amounts use the Philippine Peso (₱) symbol with
/// comma-thousands separators. Date/time helpers produce locale-consistent
/// short strings without requiring the `intl` package.
///
/// Usage:
/// ```dart
/// AppFormatters.currency(1234.5);   // → '₱1,234.50'
/// AppFormatters.shortDate(now);     // → 'Jan 15, 2025'
/// AppFormatters.time12h(now);       // → '2:30 PM'
/// AppFormatters.quantity(3.0);      // → '3'
/// AppFormatters.quantity(1.5);      // → '1.50'
/// ```
class AppFormatters {
  AppFormatters._();

  static const _months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Returns a Philippine Peso string with thousands separators.
  /// Example: `1234.5` → `₱1,234.50`
  static String currency(double v) =>
      '₱${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

  /// Returns a short date string.
  /// Example: `Jan 15, 2025`
  static String shortDate(DateTime d) =>
      '${_months[d.month]} ${d.day}, ${d.year}';

  /// Returns a 12-hour time string.
  /// Example: `2:30 PM`
  static String time12h(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  /// Returns a compact quantity string.
  /// Whole numbers drop the decimal: `3.0` → `'3'`, fractions keep 2 dp: `1.5` → `'1.50'`.
  static String quantity(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

  /// Capitalises the first character of [s].
  static String capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
