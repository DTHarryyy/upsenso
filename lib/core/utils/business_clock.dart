/// Single source of truth for "now"/"today" in business (Philippines) time.
///
/// The store operates on Philippine time (UTC+8, no DST). Every "today"
/// boundary in the app — dashboard stats, report periods, the AI assistant's
/// date filter, date-range pickers, purchase-order due dates — must derive
/// from this clock instead of `DateTime.now()` directly, so a device with a
/// misconfigured timezone (or a future UTC-based shortcut) can't make "today"
/// disagree between screens again.
class BusinessClock {
  BusinessClock._();

  static const Duration _offset = Duration(hours: 8);

  /// Current moment, expressed in Philippine wall-clock time.
  static DateTime now() {
    final phInstant = DateTime.now().toUtc().add(_offset);
    return DateTime(
      phInstant.year,
      phInstant.month,
      phInstant.day,
      phInstant.hour,
      phInstant.minute,
      phInstant.second,
      phInstant.millisecond,
    );
  }

  /// Midnight today, in Philippine time.
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}
