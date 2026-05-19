import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';

class EmployeeRoleBadge extends StatelessWidget {
  final EmployeeRole role;

  const EmployeeRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (role) {
      EmployeeRole.owner => (
          const Color(0xFFEDE9FE),
          const Color(0xFF6D28D9),
        ),
      EmployeeRole.branchManager => (
          AppColors.infoSoft,
          AppColors.info,
        ),
      EmployeeRole.cashier => (
          AppColors.brandSoft,
          AppColors.brand,
        ),
      EmployeeRole.inventoryStaff => (
          AppColors.warningSoft,
          AppColors.warning,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.displayName,
        style: getOutfitStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
