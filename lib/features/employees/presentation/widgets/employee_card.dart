import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
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
    return Dismissible(
      key: ValueKey('emp_${employee.id}'),
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: const Color(0xFF6D28D9),
        icon: Icons.shield_outlined,
        label: 'Permissions',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.brand,
        icon: Icons.edit_outlined,
        label: 'Edit',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onEdit?.call();
        } else {
          onTap?.call();
        }
        return false;
      },
      child: _CardContent(
        employee: employee,
        branchName: branchName,
        onTap: onTap,
        onEdit: onEdit,
        onArchive: onArchive,
        onSuspend: onSuspend,
        onReactivate: onReactivate,
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final Employee employee;
  final String? branchName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onSuspend;
  final VoidCallback? onReactivate;

  const _CardContent({
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
    final isActive = employee.isActive;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08101828),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.success
                          : AppColors.borderSoft,
                    ),
                  ),

                  // ── Card body ────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          _AvatarWithStatus(
                            name: employee.fullName,
                            isActive: isActive,
                          ),
                          const SizedBox(width: 14),

                          // Name + meta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  employee.fullName,
                                  style: AppTextStyles.subtitle(context)
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: isActive
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (employee.email != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    employee.email!,
                                    style: getOutfitStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 6),

                                // Role · status · branch on one row
                                Row(
                                  children: [
                                    EmployeeRoleBadge(
                                      roleName: employee.roleName,
                                    ),
                                    const SizedBox(width: 6),
                                    EmployeeStatusBadge(isActive: isActive),
                                    if (branchName != null) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        IconlyLight.location,
                                        size: 11,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          branchName!,
                                          style: getOutfitStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Action menu
                          _ActionMenu(
                            employee: employee,
                            onEdit: onEdit,
                            onArchive: onArchive,
                            onSuspend: onSuspend,
                            onReactivate: onReactivate,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Avatar with status dot ──────────────────────────────────────────────────

class _AvatarWithStatus extends StatelessWidget {
  final String name;
  final bool isActive;

  const _AvatarWithStatus({required this.name, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatar(name: name, radius: 22),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? AppColors.success : const Color(0xFFCBD5E1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Swipe action background ─────────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeft) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (!isLeft) ...[
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 20),
          ],
        ],
      ),
    );
  }
}

// ── Action menu ─────────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActionSheet(
        employee: employee,
        onEdit: onEdit,
        onArchive: onArchive,
        onSuspend: onSuspend,
        onReactivate: onReactivate,
      ),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onSuspend;
  final VoidCallback? onReactivate;

  const _ActionSheet({
    required this.employee,
    this.onEdit,
    this.onArchive,
    this.onSuspend,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18101828),
            blurRadius: 32,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPad > 0 ? 0 : 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header: employee info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    UserAvatar(name: employee.fullName, radius: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.fullName,
                            style: getOutfitStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (employee.roleName != null)
                            Text(
                              employee.roleName!,
                              style: getOutfitStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 4),

              if (onEdit != null)
                _SheetTile(
                  icon: IconlyLight.edit,
                  iconBg: AppColors.brandSoft,
                  iconColor: AppColors.brand,
                  label: 'Edit Employee',
                  onTap: () {
                    Navigator.pop(context);
                    onEdit!();
                  },
                ),

              if (employee.isActive && onSuspend != null)
                _SheetTile(
                  icon: IconlyLight.time_circle,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: AppColors.warning,
                  label: 'Suspend',
                  subtitle: 'Temporarily disable access',
                  onTap: () {
                    Navigator.pop(context);
                    onSuspend!();
                  },
                ),

              if (!employee.isActive && onReactivate != null)
                _SheetTile(
                  icon: IconlyLight.shield_done,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: AppColors.success,
                  label: 'Reactivate',
                  subtitle: 'Restore employee access',
                  onTap: () {
                    Navigator.pop(context);
                    onReactivate!();
                  },
                ),

              if (onArchive != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 16, color: AppColors.borderSoft),
                ),
                _SheetTile(
                  icon: IconlyLight.delete,
                  iconBg: const Color(0xFFFEF2F2),
                  iconColor: AppColors.error,
                  label: 'Archive',
                  subtitle: 'Remove from active team',
                  labelColor: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    onArchive!();
                  },
                ),
              ],

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = labelColor ?? AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: getOutfitStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
