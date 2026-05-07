import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

ThemeData buildLightAppTheme() {
  final baseTextTheme = getOutfitTextTheme();

  return ThemeData(
    useMaterial3: true,

    // VisualDensity.adaptivePlatformDensity returns compact (-1, -1) on
    // desktop/web and standard (0, 0) on mobile — tightens Material widget
    // padding automatically so the app feels native-density on each platform.
    visualDensity: VisualDensity.adaptivePlatformDensity,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.light,
    ),

    textTheme: baseTextTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),

    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    dividerColor: AppColors.divider,

    // Subtle hover / highlight tints.  InkWell on web shows these on mouse-over;
    // on touch they collapse to the shorter splash animation.
    hoverColor: AppColors.brand.withValues(alpha: 0.045),
    highlightColor: AppColors.brand.withValues(alpha: 0.07),

    // ── App bar ───────────────────────────────────────────────────────────
    // Left-align title on web (matches browser conventions); centre on mobile.
    appBarTheme: AppBarTheme(
      centerTitle: !kIsWeb,
      backgroundColor: AppColors.surface,
      elevation: 0,
      titleTextStyle: getOutfitStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),

    // ── Card ──────────────────────────────────────────────────────────────
    // Flat cards with a hairline border feel sharper and more modern than
    // elevated cards on web.
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderSoft),
      ),
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),

    // ── Buttons ───────────────────────────────────────────────────────────
    // mouseCursor: click ensures the browser shows the hand cursor on hover —
    // without this, Material buttons show the default arrow on web.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.textInverse,
        textStyle: getOutfitStyle(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brand,
        textStyle: getOutfitStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.brand),
    ),

    // ── Input ─────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
    ),

    // ── Scrollbar ─────────────────────────────────────────────────────────
    // Always-visible, thin scrollbar on web; native (auto-hide) on mobile.
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(kIsWeb),
      trackVisibility: WidgetStateProperty.all(false),
      thickness: WidgetStateProperty.all(kIsWeb ? 4.0 : 6.0),
      radius: const Radius.circular(4),
      thumbColor: WidgetStateProperty.all(
        AppColors.textMuted.withValues(alpha: 0.50),
      ),
      // Increase interactive hit-slop so a 4-px thumb is still easy to grab.
      interactive: true,
    ),

    // ── Dialog ────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

ThemeData buildDarkAppTheme() {
  final baseTextTheme = getOutfitTextTheme();

  return ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.dark,
    ),
    textTheme: baseTextTheme,
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(kIsWeb),
      thickness: WidgetStateProperty.all(kIsWeb ? 4.0 : 6.0),
      radius: const Radius.circular(4),
      thumbColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.30)),
    ),
  );
}

ThemeData buildAppTheme() => buildLightAppTheme();
