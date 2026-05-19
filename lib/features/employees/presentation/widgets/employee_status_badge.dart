import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';

class EmployeeStatusBadge extends StatelessWidget {
  final EmployeeStatus status;

  const EmployeeStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      EmployeeStatus.active => (
        AppColors.successSoft,
        AppColors.success,
        'Active',
      ),
      EmployeeStatus.suspended => (
        AppColors.warningSoft,
        AppColors.warning,
        'Suspended',
      ),
      EmployeeStatus.archived => (
        AppColors.surfaceAlt,
        AppColors.textMuted,
        'Archived',
      ),
    };

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
