import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

class EmployeeStatusBadge extends StatelessWidget {
  final bool isActive;

  const EmployeeStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = isActive
        ? (AppColors.successSoft, AppColors.success, 'Active')
        : (AppColors.surfaceAlt, AppColors.textMuted, 'Inactive');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: getOutfitStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
