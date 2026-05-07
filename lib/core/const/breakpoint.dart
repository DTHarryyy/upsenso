import 'package:flutter/widgets.dart';

/// Screen-class breakpoints.
///
///  phone   < 600 px
///  tablet  ≥ 600 px   (also covers landscape phone)
///  desktop ≥ 1024 px
///  large   ≥ 1440 px
class Breakpoints {
  // ── Predicates ────────────────────────────────────────────────────────────

  static bool isPhone(BuildContext c) => MediaQuery.sizeOf(c).width < 600;
  static bool isTablet(BuildContext c) => MediaQuery.sizeOf(c).width >= 600;
  static bool isDesktop(BuildContext c) => MediaQuery.sizeOf(c).width >= 1024;
  static bool isLargeDesktop(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= 1440;

  // ── Layout helpers ────────────────────────────────────────────────────────

  /// Horizontal edge padding that scales with screen width.
  ///
  /// Use this instead of a hard-coded `EdgeInsets.symmetric(horizontal: 16)`
  /// so content breathes more on wider screens.
  static double horizontalPadding(BuildContext c) {
    if (isDesktop(c)) return 32;
    if (isTablet(c)) return 24;
    return 16;
  }

  /// Maximum content width for centred page layouts (e.g. settings, forms).
  ///
  /// Wrap scrollable page content in a `Center > ConstrainedBox(maxWidth: …)`
  /// so text columns don't stretch to 2 000 px on an ultra-wide monitor.
  static double maxContentWidth(BuildContext c) {
    if (isLargeDesktop(c)) return 1280;
    if (isDesktop(c)) return 1080;
    return double.infinity; // tablet / phone — let it fill naturally
  }

  /// Maximum width for dialog / sheet content on desktop.
  static double maxDialogWidth(BuildContext c) {
    if (isDesktop(c)) return 560;
    if (isTablet(c)) return 480;
    return double.infinity;
  }
}
