import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// Small uppercase label for grouping fields inside a filter/form sheet.
class AppSectionLabel extends StatelessWidget {
  final String label;
  const AppSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: getOutfitStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}
