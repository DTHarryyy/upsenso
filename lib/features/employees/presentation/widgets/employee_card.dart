import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/presentation/widgets/employee_role_badge.dart';
import 'package:pos/features/employees/presentation/widgets/employee_status_badge.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final String? branchName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onSuspend;
  final VoidCallback? onReactivate;

  const EmployeeCard({
    super.key,
    required this.employee,
    this.branchName,
    this.onTap,
    this.onEdit,
    this.onArchive,
    this.onSuspend,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06101828),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────
            Row(
              children: [
                UserAvatar(
                  avatarUrl: employee.profileImageUrl,
                  name: employee.fullName,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: AppTextStyles.subtitle(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        employee.email,
                        style: getOutfitStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _ActionMenu(
                  employee: employee,
                  onEdit: onEdit,
                  onArchive: onArchive,
                  onSuspend: onSuspend,
                  onReactivate: onReactivate,
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.borderSoft, height: 1),
            const SizedBox(height: 12),

            // ── Meta row ───────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EmployeeRoleBadge(role: employee.role),
                EmployeeStatusBadge(status: employee.status),
              ],
            ),

            if (branchName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.store_outlined,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    branchName!,
                    style: getOutfitStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  employee.employeeCode,
                  style: getOutfitStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onSuspend;
  final VoidCallback? onReactivate;

  const _ActionMenu({
    required this.employee,
    this.onEdit,
    this.onArchive,
    this.onSuspend,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textMuted,
        size: 20,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
          case 'suspend':
            onSuspend?.call();
          case 'reactivate':
            onReactivate?.call();
          case 'archive':
            onArchive?.call();
        }
      },
      itemBuilder: (_) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: _MenuItem(icon: Icons.edit_outlined, label: 'Edit'),
          ),
        if (employee.status == EmployeeStatus.active && onSuspend != null)
          const PopupMenuItem(
            value: 'suspend',
            child: _MenuItem(
              icon: Icons.pause_circle_outline,
              label: 'Suspend',
              color: AppColors.warning,
            ),
          ),
        if (employee.status != EmployeeStatus.active && onReactivate != null)
          const PopupMenuItem(
            value: 'reactivate',
            child: _MenuItem(
              icon: Icons.check_circle_outline,
              label: 'Reactivate',
              color: AppColors.success,
            ),
          ),
        if (employee.status != EmployeeStatus.archived && onArchive != null)
          const PopupMenuItem(
            value: 'archive',
            child: _MenuItem(
              icon: Icons.archive_outlined,
              label: 'Archive',
              color: AppColors.error,
            ),
          ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: getOutfitStyle(fontSize: 13, color: color),
        ),
      ],
    );
  }
}
