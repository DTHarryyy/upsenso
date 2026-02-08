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

  /// Enterprise trick: allow accessibility scaling, but cap it for tight POS UI.
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

  static TextStyle display(BuildContext c) => TextStyle(
    fontSize: 30 * ResponsiveTypography.scale(c),
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static TextStyle headline(BuildContext c) => TextStyle(
    fontSize: 24 * ResponsiveTypography.scale(c),
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static TextStyle title(BuildContext c) => TextStyle(
    fontSize: 18 * ResponsiveTypography.scale(c),
    fontWeight: FontWeight.w700,
    height: 1.20,
  );

  static TextStyle subtitle(BuildContext c) => TextStyle(
    fontSize: 16 * ResponsiveTypography.scale(c),
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static TextStyle body(BuildContext c) => TextStyle(
    fontSize: 14 * ResponsiveTypography.scale(c),
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static TextStyle caption(BuildContext c) => TextStyle(
    fontSize: 12 * ResponsiveTypography.scale(c),
    fontWeight: FontWeight.w400,
    height: 1.25,
  );

  static TextStyle money(BuildContext c) => TextStyle(
    fontSize: 16 * ResponsiveTypography.scale(c),
    fontWeight: FontWeight.w700,
    height: 1.15,
  );
}
