import 'package:flutter/material.dart';

/// Returns a [TextStyle] with no explicit [fontFamily].
///
/// Omitting [fontFamily] lets Flutter's theme system resolve the correct font
/// per platform:
///   • Android / Linux: Roboto (system font)
///   • iOS / macOS: SF Pro (system font)
///   • Web (CanvasKit / SkWasm): engine default (Noto-based fallback chain)
///
/// Specifying `fontFamily: 'Roboto'` on web causes CanvasKit to attempt to
/// load Roboto from the app's asset bundle. Since Roboto is not declared in
/// pubspec.yaml, CanvasKit falls back to Noto — but the mismatch between the
/// requested and resolved font triggers sub-pixel placement differences that
/// appear as blurry or slightly-off text. Removing the override eliminates
/// this discrepancy and produces consistently sharp text on all platforms.
TextStyle getOutfitStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.normal,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    // No fontFamily — resolved by the platform / engine default.
  );
}

/// Safe text theme getter that builds theme without calling GoogleFonts methods
/// This prevents font loading errors from being logged
TextTheme getOutfitTextTheme() {
  return TextTheme(
    // Display styles
    displayLarge: getOutfitStyle(fontSize: 57, fontWeight: FontWeight.w400),
    displayMedium: getOutfitStyle(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: getOutfitStyle(fontSize: 36, fontWeight: FontWeight.w500),

    // Headline styles
    headlineLarge: getOutfitStyle(fontSize: 32, fontWeight: FontWeight.w400),
    headlineMedium: getOutfitStyle(fontSize: 28, fontWeight: FontWeight.w500),
    headlineSmall: getOutfitStyle(fontSize: 24, fontWeight: FontWeight.w500),

    // Title styles
    titleLarge: getOutfitStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: getOutfitStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: getOutfitStyle(fontSize: 14, fontWeight: FontWeight.w600),

    // Body styles
    bodyLarge: getOutfitStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: getOutfitStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: getOutfitStyle(fontSize: 12, fontWeight: FontWeight.w400),

    // Label styles
    labelLarge: getOutfitStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: getOutfitStyle(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall: getOutfitStyle(fontSize: 11, fontWeight: FontWeight.w600),
  );
}
