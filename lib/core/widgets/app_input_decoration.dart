import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// Returns a consistent [InputDecoration] used across all form fields.
///
/// - [hint] — placeholder text shown when the field is empty
/// - [label] — floating label that lifts when focused or filled (Stripe-style)
/// - [prefixText] — optional currency/unit prefix (e.g. '₱ ')
/// - [radius] — corner radius (default 10)
/// - [fillColor] — override the background fill (defaults to [AppColors.inputFill])
/// - [isDense] — reduces field height (default false)
InputDecoration appInputDeco(
  String? hint, {
  String? label,
  String? prefixText,
  double radius = 10,
  Color? fillColor,
  bool isDense = false,
}) {
  final hasLabel = label != null;
  final effectiveFill = fillColor ?? (hasLabel ? AppColors.surface : AppColors.inputFill);
  final hasBorder = effectiveFill == AppColors.surface;

  final restingBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: hasBorder
        ? const BorderSide(color: AppColors.borderSoft, width: 1)
        : BorderSide.none,
  );

  return InputDecoration(
    labelText: label,
    labelStyle: getOutfitStyle(
      color: AppColors.textMuted,
      fontSize: 15,
    ),
    floatingLabelStyle: getOutfitStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelBehavior: hasLabel ? FloatingLabelBehavior.auto : FloatingLabelBehavior.never,
    hintText: hint,
    hintStyle: getOutfitStyle(color: AppColors.textMuted),
    prefixText: prefixText,
    prefixStyle: getOutfitStyle(
      color: AppColors.textMuted,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: effectiveFill,
    isDense: isDense,
    border: restingBorder,
    enabledBorder: restingBorder,
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
    contentPadding: hasLabel
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 16)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}
