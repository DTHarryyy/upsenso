import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Returns a [TextStyle] using the correct font for each platform.
///
/// **Web** — Inter (Google Fonts).  Inter is a variable-weight typeface
/// designed specifically for screen readability.  GoogleFonts injects a single
/// CSS @font-face rule at runtime and the browser caches the file; on
/// subsequent loads (including offline reloads after first visit) the font is
/// served from the browser cache so the app stays fully offline-capable.
///
/// **Mobile / desktop native** — no explicit [fontFamily] so Flutter's theme
/// resolves the platform system font:
///   • Android / Linux → Roboto
///   • iOS / macOS     → SF Pro
///
/// Why not specify 'Roboto' on mobile?  On web, CanvasKit/SkWasm attempt to
/// load the requested family from Flutter's asset bundle.  If Roboto is not
/// declared in pubspec.yaml the engine falls back to Noto, but the mismatch
/// between the requested and resolved font triggers sub-pixel glyph-placement
/// differences that appear as blurry text.  Omitting the family entirely
/// removes the mismatch and produces consistently sharp glyphs on every target.
TextStyle getOutfitStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.normal,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  if (kIsWeb) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// Full Material 3 [TextTheme] using the platform-appropriate font.
///
/// On web, every slot is Inter so the entire app uses a consistent,
/// web-native typeface — no per-widget font overrides needed.
TextTheme getOutfitTextTheme() {
  return TextTheme(
    displayLarge: getOutfitStyle(fontSize: 57, fontWeight: FontWeight.w400),
    displayMedium: getOutfitStyle(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: getOutfitStyle(fontSize: 36, fontWeight: FontWeight.w500),

    headlineLarge: getOutfitStyle(fontSize: 32, fontWeight: FontWeight.w400),
    headlineMedium: getOutfitStyle(fontSize: 28, fontWeight: FontWeight.w500),
    headlineSmall: getOutfitStyle(fontSize: 24, fontWeight: FontWeight.w500),

    titleLarge: getOutfitStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: getOutfitStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: getOutfitStyle(fontSize: 14, fontWeight: FontWeight.w600),

    bodyLarge: getOutfitStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: getOutfitStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: getOutfitStyle(fontSize: 12, fontWeight: FontWeight.w400),

    labelLarge: getOutfitStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: getOutfitStyle(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall: getOutfitStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );
}

/// Maps internal role names to user-facing display labels.
///
/// `'Super Admin'` → `'Owner'` (internal name not exposed to users)
/// All other names pass through unchanged.
/// Returns `null` when [roleName] is null.
String? displayRoleName(String? roleName) {
  if (roleName == null) return null;
  final n = roleName.trim().toLowerCase();
  if (n == 'business owner' || n == 'super admin' || n == 'superadmin') return 'Business Owner';
  return roleName;
}
