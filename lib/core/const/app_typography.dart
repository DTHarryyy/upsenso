import 'package:flutter/material.dart';

enum DeviceClass { phone, tablet, desktop }

class ResponsiveTypography {
  static DeviceClass deviceClass(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1024) return DeviceClass.desktop;
    if (w >= 600) return DeviceClass.tablet;
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
  // positions inside the CanvasKit WebGL canvas land on integer physical
  // pixels.  Fractional font sizes (e.g. 14 × 1.20 = 16.8 px) cause
  // sub-pixel glyph placement which appears as text blur, especially at
  // non-integer devicePixelRatio values common on Windows high-DPI displays.
  static double _fs(BuildContext c, double base) =>
      (base * ResponsiveTypography.scale(c)).roundToDouble();

  static TextStyle display(BuildContext c) => TextStyle(
    fontSize: _fs(c, 30),
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static TextStyle headline(BuildContext c) => TextStyle(
    fontSize: _fs(c, 24),
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static TextStyle title(BuildContext c) => TextStyle(
    fontSize: _fs(c, 18),
    fontWeight: FontWeight.w700,
    height: 1.20,
  );

  static TextStyle subtitle(BuildContext c) => TextStyle(
    fontSize: _fs(c, 16),
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static TextStyle body(BuildContext c) => TextStyle(
    fontSize: _fs(c, 14),
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static TextStyle caption(BuildContext c) => TextStyle(
    fontSize: _fs(c, 12),
    fontWeight: FontWeight.w400,
    height: 1.25,
  );

  static TextStyle money(BuildContext c) => TextStyle(
    fontSize: _fs(c, 16),
    fontWeight: FontWeight.w700,
    height: 1.15,
  );
}
