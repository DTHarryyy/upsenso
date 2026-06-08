import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/presentation/widgets/employee_role_badge.dart';
import 'package:pos/features/employees/presentation/widgets/employee_status_badge.dart';

class EmployeeDetailsPage extends StatelessWidget {
  final Employee employee;
  final String? branchName;

  const EmployeeDetailsPage({
    super.key,
    required this.employee,
    this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageBar(title: 'Employee Details'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile header ───────────────────────────────────────────
          _ProfileHeader(employee: employee),
          const SizedBox(height: 16),

          // ── Status & Role ────────────────────────────────────────────
          AppSectionCard(
            title: 'Role & Status',
            icon: IconlyLight.shield_done,
            children: [
              _DetailRow(
                label: 'Status',
                value: EmployeeStatusBadge(isActive: employee.isActive),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Role',
                value: EmployeeRoleBadge(roleName: employee.roleName),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Assignment ───────────────────────────────────────────────
          AppSectionCard(
            title: 'Branch Assignment',
            icon: IconlyLight.location,
            children: [
              _DetailRow(
                label: 'Branch',
                value: Text(
                  branchName ?? employee.branchId ?? '-',
                  style: getOutfitStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Timeline ─────────────────────────────────────────────────
          AppSectionCard(
            title: 'Timeline',
            icon: IconlyLight.time_circle,
            children: [
              _DetailRow(
                label: 'Created',
                value: Text(
                  employee.createdAt != null
                      ? _formatDate(employee.createdAt!)
                      : '-',
                  style: getOutfitStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          // ── Permission overrides (owner/admin only) ──────────────────
          if (sl<PermissionService>().can(PermissionKeys.employeesAssignRole)) ...[
            const SizedBox(height: 16),
            _ManagePermissionsButton(employee: employee),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Employee employee;
  const _ProfileHeader({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: null,
            name: employee.fullName,
            radius: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: AppTextStyles.headline(context).copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    EmployeeRoleBadge(roleName: employee.roleName),
                    const SizedBox(width: 8),
                    EmployeeStatusBadge(isActive: employee.isActive),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Manage Permissions Button ──────────────────────────────────────────────

class _ManagePermissionsButton extends StatelessWidget {
  final Employee employee;
  const _ManagePermissionsButton({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push(AppRoutes.employeePermissions, extra: employee),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  IconlyLight.shield_done,
                  size: 20,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permission Overrides',
                      style: getOutfitStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Grant or deny specific permissions for this employee',
                      style: getOutfitStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                IconlyLight.arrow_right_2,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail Row ─────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: getOutfitStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: value),
      ],
    );
  }
}
