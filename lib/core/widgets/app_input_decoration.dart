import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// Returns a consistent [InputDecoration] used across all form fields.
///
/// - [hint] — placeholder text shown when the field is empty
/// - [prefixText] — optional currency/unit prefix (e.g. '₱ ')
/// - [radius] — corner radius (default 10)
/// - [fillColor] — override the background fill (defaults to [AppColors.inputFill])
/// - [isDense] — reduces field height (default false)
InputDecoration appInputDeco(
  String? hint, {
  String? prefixText,
  double radius = 10,
  Color? fillColor,
  bool isDense = false,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide.none,
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: getOutfitStyle(color: AppColors.textMuted),
    prefixText: prefixText,
    filled: true,
    fillColor: fillColor ?? AppColors.inputFill,
    isDense: isDense,
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}
