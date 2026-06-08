import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/expenses/presentation/expenses_page.dart';
import 'package:pos/features/sales/presentation/sales_history.dart';
import 'package:pos/features/audit_logs/presentation/pages/audit_log_page.dart';
import 'package:pos/features/employees/presentation/pages/employees_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage>
    with SingleTickerProviderStateMixin {
  bool _settingsExpanded = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleSettings() {
    setState(() => _settingsExpanded = !_settingsExpanded);
    _settingsExpanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  void _navigate(String route) {
    Navigator.of(context).pop(); // close drawer
    context.push(route);
  }

  void _pushFullPage(Widget page) {
    Navigator.of(context).pop(); // close drawer
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => page));
  }

  void _showLogoutDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log out?',
          style: getOutfitStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: getOutfitStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Log out',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true && mounted) {
        context.read<AuthBloc>().add(AuthLogoutRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final name = user?.fullName ?? user?.email ?? 'User';
        final role = displayRoleName(user?.roleName) ?? '';
        final business = user?.businessName ?? '';

        final permService = sl<PermissionService>();
        // Feature-based visibility — no raw role-string comparisons.
        // isRestrictedEmployee: roles without expense-module access (cashier, inventory_staff).
        final isRestrictedEmployee = !permService.can(
          PermissionKeys.navExpenses,
        );
        // Audit logs: owner / super_admin only (branchManager excluded by permission matrix).
        final canSeeAuditLogs = permService.can(PermissionKeys.navAuditLogs) &&
            permService.isModuleEnabled('audit');
        // Employee management: branchManager / owner / super_admin.
        final canSeeEmployees = permService.can(PermissionKeys.navEmployees) &&
            permService.isModuleEnabled('employees');

        return SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              _DrawerHeader(
                name: name,
                role: role,
                business: business,
                avatarUrl: user?.avatarUrl,
                email: user?.email,
                onTap: () => _navigate(AppRoutes.profile),
              ),

              // ── Nav list ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PROFILE — cashier & inventory staff only
                      // (header avatar already navigates to profile, but an
                      // explicit tile makes it obvious and discoverable).
                      if (isRestrictedEmployee) ...[
                        _SectionLabel('ACCOUNT'),
                        _DrawerTile(
                          icon: IconlyLight.profile,
                          label: 'My Profile',
                          onTap: () => _navigate(AppRoutes.profile),
                        ),
                        const SizedBox(height: 4),
                        _Divider(),
                        const SizedBox(height: 4),
                      ],

                      // OPERATIONS — hidden for cashier/inventory staff and when expenses module is off
                      if (!isRestrictedEmployee &&
                          permService.isModuleEnabled('expenses')) ...[
                        _SectionLabel('OPERATIONS'),
                        _DrawerTile(
                          icon: IconlyLight.time_circle,
                          label: 'Sales History',
                          onTap: () => _pushFullPage(const SalesHistory()),
                        ),
                        _DrawerTile(
                          icon: IconlyLight.wallet,
                          label: 'Expenses',
                          onTap: () => _pushFullPage(const ExpensesPage()),
                        ),
                        const SizedBox(height: 4),
                        _Divider(),
                        const SizedBox(height: 4),
                      ], // end OPERATIONS
                      // ADMIN
                      if (canSeeEmployees || canSeeAuditLogs) ...[
                        _SectionLabel('ADMIN'),
                        if (canSeeEmployees)
                          _DrawerTile(
                            icon: IconlyLight.profile,
                            label: 'Employees',
                            onTap: () => _pushFullPage(const EmployeesPage()),
                          ),
                        if (canSeeAuditLogs)
                          _DrawerTile(
                            icon: IconlyLight.shield_done,
                            label: 'Audit Logs',
                            onTap: () => _pushFullPage(const AuditLogPage()),
                          ),
                        const SizedBox(height: 4),
                        _Divider(),
                        const SizedBox(height: 4),
                      ],

                      // SETTINGS (expandable) — hidden for restricted employees
                      if (!isRestrictedEmployee) ...[
                        _SectionLabel('SETTINGS'),
                        _SettingsTile(
                          isExpanded: _settingsExpanded,
                          onTap: _toggleSettings,
                        ),
                        SizeTransition(
                          sizeFactor: _expandAnim,
                          axisAlignment: -1,
                          child: _SettingsSubItems(
                            onNavigate: _navigate,
                            onModulesTap: permService.can(
                              PermissionKeys.settingsEditBusiness,
                            )
                                ? () {
                                    Navigator.of(context).pop();
                                    context.push(
                                      AppRoutes.moduleSettings,
                                      extra: user?.businessId ?? '',
                                    );
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Logout ────────────────────────────────────────────────
              _LogoutButton(onTap: _showLogoutDialog),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String role;
  final String business;
  final String? avatarUrl;
  final String? email;
  final VoidCallback onTap;

  const _DrawerHeader({
    required this.name,
    required this.role,
    required this.business,
    required this.avatarUrl,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
        ),
        child: Row(
          children: [
            UserAvatar(
              avatarUrl: avatarUrl,
              name: name,
              email: email,
              radius: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (role.isNotEmpty || business.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (role.isNotEmpty) role,
                        if (business.isNotEmpty) business,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getOutfitStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Standard drawer tile ───────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Settings expandable header tile ────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _SettingsTile({required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isExpanded ? AppColors.brandSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.brand.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(
                  isExpanded ? IconlyBold.setting : IconlyLight.setting,
                  size: 20,
                  color: isExpanded ? AppColors.brand : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Settings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: isExpanded
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isExpanded
                          ? AppColors.textPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 240),
                  child: const Icon(
                    IconlyLight.arrow_down_2,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Settings sub-items ─────────────────────────────────────────────────────

class _SettingsSubItems extends StatelessWidget {
  final void Function(String route) onNavigate;
  final VoidCallback? onModulesTap;

  const _SettingsSubItems({
    required this.onNavigate,
    this.onModulesTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: IconlyLight.paper,
        label: 'Receipt Settings',
        onTap: () => onNavigate(AppRoutes.receiptSettings),
      ),
      (
        icon: IconlyLight.work,
        label: 'Business Profile',
        onTap: () => onNavigate(AppRoutes.businessProfile),
      ),
      (
        icon: IconlyLight.profile,
        label: 'My Profile',
        onTap: () => onNavigate(AppRoutes.profile),
      ),
      if (onModulesTap != null)
        (
          icon: IconlyLight.setting,
          label: 'Module Management',
          onTap: onModulesTap!,
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 12, bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.brand.withValues(alpha: 0.25),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: items.map((item) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(8),
              splashColor: AppColors.brand.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18, color: AppColors.brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getOutfitStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.north_east_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
      child: Text(
        text,
        style: getOutfitStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.borderSoft,
    );
  }
}

// ── Logout ─────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(IconlyLight.logout, size: 18),
          label: const Text('Log Out'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: getOutfitStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
