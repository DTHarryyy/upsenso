import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/presentation/bloc/employee_activity_cubit.dart';
import 'package:pos/features/employees/presentation/bloc/employee_activity_state.dart';
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
    final canManagePermissions = sl<PermissionService>().can(
      PermissionKeys.employeesAssignRole,
    );
    // set_manager_pin only allows the business owner (or super admin) to
    // target another employee — matches that server-side rule exactly so
    // this button never appears for someone it would just fail for (e.g. a
    // Branch Manager who holds employeesAssignRole but isn't the owner).
    final isOwner = sl<PermissionService>().isOwnerRole;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageBar(
        title: 'Employee Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, size: 22),
            color: AppColors.textSecondary,
            onPressed: () => _showOverflowMenu(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _EmployeeProfileHeader(employee: employee),
          const SizedBox(height: 8),
          _EmployeeOverviewCard(employee: employee, branchName: branchName),
          const SizedBox(height: 8),
          if (canManagePermissions) ...[
            _PermissionsCard(employee: employee),
            const SizedBox(height: 8),
          ],
          if (isOwner) ...[
            _ManagerPinCard(employee: employee),
            const SizedBox(height: 8),
          ],
          BlocProvider(
            create: (_) =>
                EmployeeActivityCubit(sl<IAuditLogRepository>())
                  ..load(employee),
            child: const _SecurityActivityCard(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showOverflowMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OverflowSheet(employee: employee),
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────

class _EmployeeProfileHeader extends StatelessWidget {
  final Employee employee;

  const _EmployeeProfileHeader({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatar(avatarUrl: null, name: employee.fullName, radius: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: AppTextStyles.title(
                    context,
                  ).copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Role/branch dropped here — Employee Overview below already
                // shows both, so only status is worth surfacing in the header.
                EmployeeStatusBadge(isActive: employee.isActive),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Employee Overview Card ─────────────────────────────────────────────────

class _EmployeeOverviewCard extends StatelessWidget {
  final Employee employee;
  final String? branchName;

  const _EmployeeOverviewCard({
    required this.employee,
    required this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    final branch = branchName ?? employee.branchId ?? '—';
    final createdOn = employee.createdAt != null
        ? _formatDate(employee.createdAt!)
        : '—';

    return _InfoCard(
      icon: IconlyLight.profile,
      title: 'Employee Overview',
      children: [
        _InfoRow(
          icon: IconlyLight.work,
          label: 'Role',
          child: EmployeeRoleBadge(roleName: employee.roleName),
        ),
        _Divider(),
        _InfoRow(icon: IconlyLight.location, label: 'Branch', value: branch),
        _Divider(),
        _InfoRow(
          icon: IconlyLight.message,
          label: 'Email',
          value: employee.email ?? '—',
        ),
        _Divider(),
        _InfoRow(
          icon: IconlyLight.calendar,
          label: 'Created On',
          value: createdOn,
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Permissions Card ───────────────────────────────────────────────────────

class _PermissionsCard extends StatelessWidget {
  final Employee employee;

  const _PermissionsCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  IconlyLight.shield_done,
                  size: 18,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Permissions',
                style: AppTextStyles.subtitle(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Customize this employee\'s access beyond their default role permissions.',
            style: getOutfitStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _ManagePermissionsButton(employee: employee),
        ],
      ),
    );
  }
}

class _ManagePermissionsButton extends StatelessWidget {
  final Employee employee;

  const _ManagePermissionsButton({required this.employee});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () =>
            context.push(AppRoutes.employeePermissions, extra: employee),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: const Icon(IconlyLight.setting, size: 16, color: Colors.white),
        label: Text(
          'Manage Permissions',
          style: getOutfitStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Manager PIN Card ────────────────────────────────────────────────────────

class _ManagerPinCard extends StatelessWidget {
  final Employee employee;

  const _ManagerPinCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  IconlyLight.lock,
                  size: 18,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Manager PIN',
                style: AppTextStyles.subtitle(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Reset the PIN this employee uses to authorise over-limit refunds.',
            style: getOutfitStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  context.push(AppRoutes.managerPin, extra: employee),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              icon: const Icon(IconlyLight.lock, size: 16, color: Colors.white),
              label: Text(
                'Reset Manager PIN',
                style: getOutfitStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Security & Activity Card ───────────────────────────────────────────────

class _SecurityActivityCard extends StatelessWidget {
  const _SecurityActivityCard();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: IconlyLight.shield_done,
      iconColor: AppColors.success,
      title: 'Security & Activity',
      children: [
        BlocBuilder<EmployeeActivityCubit, EmployeeActivityState>(
          builder: (context, state) {
            final loaded = state is EmployeeActivityLoaded ? state : null;
            final lastLogin = loaded?.lastLogin;
            final device = loaded?.device;
            final recentLabel = loaded?.recentActivityLabel;
            final recentTime = loaded?.recentActivityTime;
            final mutedStyle = getOutfitStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            );

            return Column(
              children: [
                _InfoRow(
                  icon: IconlyLight.time_circle,
                  label: 'Last Login',
                  value: lastLogin != null
                      ? '${AppFormatters.shortDate(lastLogin)} · ${AppFormatters.time12h(lastLogin)}'
                      : 'Not available',
                  valueStyle: mutedStyle,
                ),
                _Divider(),
                _InfoRow(
                  icon: IconlyLight.scan,
                  label: 'Device',
                  value: device ?? 'Not available',
                  valueStyle: mutedStyle,
                ),
                _Divider(),
                _InfoRow(
                  icon: IconlyLight.activity,
                  label: 'Recent Activity',
                  value: recentLabel != null && recentTime != null
                      ? '$recentLabel · ${AppFormatters.relativeDate(recentTime)}'
                      : 'No recent activity',
                  valueStyle: mutedStyle,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
// TODO: fraud flags are not yet implemented on the backend, so this badge is not currently used. It will be added to the Employee Overview card once the feature is available.
// class _FraudFlagBadge extends StatelessWidget {
//   final int flagCount;

//   const _FraudFlagBadge({required this.flagCount});

//   @override
//   Widget build(BuildContext context) {
//     final isClean = flagCount == 0;
//     final bg = isClean ? AppColors.successSoft : AppColors.errorSoft;
//     final fg = isClean ? AppColors.success : AppColors.error;
//     final label = isClean
//         ? 'None Detected'
//         : '$flagCount Flag${flagCount > 1 ? 's' : ''}';

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//           decoration: BoxDecoration(
//             color: bg,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 isClean
//                     ? Icons.check_circle_outline_rounded
//                     : Icons.flag_rounded,
//                 size: 12,
//                 color: fg,
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 label,
//                 style: getOutfitStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                   color: fg,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// ── Overflow Sheet ─────────────────────────────────────────────────────────

class _OverflowSheet extends StatelessWidget {
  final Employee employee;

  const _OverflowSheet({required this.employee});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SheetAction(
              icon: IconlyLight.activity,
              label: 'View Activity Log',
              onTap: () => Navigator.of(context).pop(),
            ),
            _SheetAction(
              icon: IconlyLight.message,
              label: 'Send Message',
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const fg = AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, size: 20, color: fg),
      title: Text(
        label,
        style: getOutfitStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }
}

// ── Shared: Info Card ──────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = iconColor ?? AppColors.brand;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: fg.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: fg),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.subtitle(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Shared: Info Row ───────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.child,
    this.valueStyle,
  }) : assert(
         value != null || child != null,
         '_InfoRow requires either value or child',
       );

  @override
  Widget build(BuildContext context) {
    final effectiveValueStyle =
        valueStyle ??
        getOutfitStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: getOutfitStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  child ??
                  Text(
                    value!,
                    style: effectiveValueStyle,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared: Divider ────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderSoft,
      indent: 20,
      endIndent: 20,
    );
  }
}
