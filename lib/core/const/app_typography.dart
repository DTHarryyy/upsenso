import 'package:flutter/material.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';

enum DeviceClass { phone, tablet, desktop }

class ResponsiveTypography {
  static DeviceClass deviceClass(BuildContext context) {
    if (Breakpoints.isDesktop(context)) return DeviceClass.desktop;
    if (Breakpoints.isTablet(context)) return DeviceClass.tablet;
    return DeviceClass.phone;
  }

  static double scale(BuildContext context) {
    switch (deviceClass(context)) {
      case DeviceClass.phone:
        return 1.0;
      case DeviceClass.tablet:
        return 1.10;
      case DeviceClass.desktop:
        return 1.20;
    }
  }

  static TextScaler safeScaler(
    BuildContext context, {
    double min = 1.0,
    double max = 1.25,
  }) {
    return MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: min, maxScaleFactor: max);
  }
}

class AppTextStyles {
  AppTextStyles._();

  // Rounds the scaled font size to the nearest whole number so that glyph
  // positions inside the CanvasKit/SkWasm WebGL canvas land on integer physical
  // pixels.  Fractional font sizes (e.g. 14 × 1.20 = 16.8 px) cause sub-pixel
  // glyph placement which appears as text blur on non-integer DPR displays.
  static double _fs(BuildContext c, double base) =>
      (base * ResponsiveTypography.scale(c)).roundToDouble();

  // All styles go through getOutfitStyle so they automatically pick up Inter
  // on web and the system font on native — no per-call kIsWeb checks needed.

  static TextStyle display(BuildContext c) => getOutfitStyle(
    fontSize: _fs(c, 30),
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static TextStyle headline(BuildContext c) => getOutfitStyle(
    fontSize: _fs(c, 24),
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static TextStyle title(BuildContext c) => getOutfitStyle(
    fontSize: _fs(c, 18),
    fontWeight: FontWeight.w700,
    height: 1.20,
  );

  static TextStyle subtitle(BuildContext c) => getOutfitStyle(
    fontSize: _fs(c, 16),
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static TextStyle body(BuildContext c) => getOutfitStyle(
    fontSize: _fs(c, 14),
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static TextStyle caption(BuildContext c) => getOutfitStyle(
    fontSize: _fs(c, 12),
    fontWeight: FontWeight.w400,
    height: 1.25,
  );

  static TextStyle money(BuildContext c) => getOutfitStyle(
    fontSize: _fs(c, 16),
    fontWeight: FontWeight.w700,
    height: 1.15,
  );
}
