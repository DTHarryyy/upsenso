import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

class EmployeeRoleBadge extends StatelessWidget {
  final String? roleName;

  const EmployeeRoleBadge({super.key, required this.roleName});

  @override
  Widget build(BuildContext context) {
    final label = roleName ?? 'No Role';
    final lowerLabel = label.toLowerCase();

    final (bg, fg) = lowerLabel.contains('admin') || lowerLabel.contains('owner')
        ? (const Color(0xFFEDE9FE), const Color(0xFF6D28D9))
        : lowerLabel.contains('manager')
            ? (AppColors.infoSoft, AppColors.info)
            : lowerLabel.contains('cashier')
                ? (AppColors.brandSoft, AppColors.brand)
                : lowerLabel.contains('inventory')
                    ? (AppColors.warningSoft, AppColors.warning)
                    : (AppColors.surfaceAlt, AppColors.textMuted);

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
