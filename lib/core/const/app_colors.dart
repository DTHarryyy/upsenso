import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color brand = Color(0xFF557FF4);
  static const Color brandDark = Color(0xFF3B5BDB);
  static const Color brandSoft = Color(0xFFEAF0FF);

  // Accent (used for highlights, charts, links)
  static const Color accent = Color(0xFF22C55E); // green (positive money)

  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color overlay = Color(0xCC000000);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color borderSoft = Color(0xFFE2E8F0);
  static const Color borderDark = Color.fromARGB(255, 81, 92, 106);
  static const Color divider = Color.fromARGB(255, 210, 214, 218);
  static const Color focus = Color(0xFF93C5FD);

  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);

  static const Color error = Color.fromARGB(255, 255, 87, 87);
  static const Color errorSoft = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFDBEAFE);
  static const Color red = Color.fromARGB(255, 238, 37, 37);

  static const Color income = Color(0xFF16A34A);
  static const Color expense = Color(0xFFDC2626);
  static const Color transfer = Color(0xFF0EA5E9);

  static const Color inStock = Color(0xFF16A34A);
  static const Color lowStock = Color(0xFFF59E0B);
  static const Color outOfStock = Color(0xFFDC2626);

  static const Color offline = Color(0xFF64748B);
  static const Color syncing = Color(0xFF557FF4);
  static const Color synced = Color(0xFF22C55E);

  static const Color fraudHigh = Color(0xFFB91C1C);
  static const Color fraudMedium = Color(0xFFF59E0B);
  static const Color fraudLow = Color(0xFF3B82F6);

  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color disabled = Color(0xFFE5E7EB);
  static const Color disabledText = Color(0xFF9CA3AF);

  static const List<Color> chartPalette = [
    brand,
    accent,
    success,
    warning,
    error,
    info,
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
  ];
}
