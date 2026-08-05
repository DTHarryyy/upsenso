import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/const/nav_feature_flags.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/feature_plan_requirement.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/plan_badge.dart';
import 'package:pos/core/widgets/plan_lock_badge.dart';
import 'package:pos/core/widgets/upgrade_prompt.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/expenses/presentation/expenses_page.dart';
import 'package:pos/features/sales/presentation/sales_history.dart';
import 'package:pos/features/drafts/presentation/held_sales_page.dart';
import 'package:pos/features/employees/presentation/pages/employees_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
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
    // Repaint on every entitlement change so a plan switch updates the lock
    // badges without a restart — same wiring PlanBadge already uses.
    return ValueListenableBuilder<int>(
      valueListenable: sl<EntitlementService>().entitlementRevision,
      builder: (context, _, _) => _buildDrawer(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
        // Audit logs: Business Owner only (branchManager excluded by permission matrix).
        final canSeeAuditLogs =
            permService.can(PermissionKeys.navAuditLogs) &&
            permService.isModuleEnabled('audit');
        // Employee management: branchManager / Business Owner.
        final canSeeEmployees =
            permService.can(PermissionKeys.navEmployees) &&
            permService.isModuleEnabled('employees');
        // Held sales: anyone who can hold a sale (incl. cashiers), POS module on.
        final canSeeHeldSales =
            permService.can(PermissionKeys.navHeldSales) &&
            permService.isModuleEnabled('pos');
        // Procurement: permission + module gate.
        final canSeeProcurement =
            permService.can(PermissionKeys.navProcurement) &&
            permService.isModuleEnabled('procurement');
        // Customers (CRM): permission + module gate.
        final canSeeCustomers =
            permService.can(PermissionKeys.navCustomers) &&
            permService.isModuleEnabled('crm');
        // Fraud & Risk: permission + audit module gate (UI only — the
        // detection engine runs regardless).
        final canSeeFraud =
            permService.can(PermissionKeys.navFraud) &&
            permService.isModuleEnabled('audit');

        // Plan locks are deliberately NOT folded into the canSee* flags above.
        // Permission and module say "hide"; the plan says "show it locked", so
        // the merchant can see what upgrading buys instead of the item silently
        // vanishing — or worse, navigating into the router's entitlement guard
        // and bouncing back to the dashboard with no explanation.
        final procurementLock = planLockFor(AppFeature.procurement);
        final customersLock = planLockFor(AppFeature.customerDirectory);
        final auditLogsLock = planLockFor(AppFeature.auditLogs);
        final fraudLock = planLockFor(AppFeature.fraudAlerts);
        // Sales history: permission only — no module gate (see AppFeature.salesHistory).
        final canSeeSalesHistory = permService.can(
          PermissionKeys.navSalesHistory,
        );

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
                      // SALES — held sales (cashiers too) + history (managers/owners)
                      if (canSeeHeldSales || canSeeSalesHistory) ...[
                        _SectionLabel('SALES'),
                        if (canSeeHeldSales)
                          _DrawerTile(
                            icon: IconlyLight.bookmark,
                            label: 'Held Sales',
                            onTap: () => _pushFullPage(const HeldSalesPage()),
                          ),
                        if (canSeeSalesHistory)
                          _DrawerTile(
                            icon: IconlyLight.time_circle,
                            label: 'Sales History',
                            onTap: () => _pushFullPage(const SalesHistory()),
                          ),
                        const SizedBox(height: 4),
                        _Divider(),
                        const SizedBox(height: 4),
                      ],

                      // PROCUREMENT — purchase orders + suppliers
                      if (canSeeProcurement) ...[
                        _SectionLabel('PROCUREMENT'),
                        _DrawerTile(
                          icon: IconlyLight.bag_2,
                          label: 'Purchase Orders',
                          lockedPlan: procurementLock,
                          onTap: () => _navigate(AppRoutes.purchaseOrders),
                        ),
                        _DrawerTile(
                          icon: IconlyLight.work,
                          label: 'Suppliers',
                          lockedPlan: procurementLock,
                          onTap: () => _navigate(AppRoutes.suppliers),
                        ),
                        const SizedBox(height: 4),
                        _Divider(),
                        const SizedBox(height: 4),
                      ],

                      // CUSTOMERS — CRM directory
                      if (canSeeCustomers) ...[
                        _SectionLabel('CUSTOMERS'),
                        _DrawerTile(
                          icon: IconlyLight.profile,
                          label: 'Customers',
                          lockedPlan: customersLock,
                          onTap: () => _navigate(AppRoutes.customers),
                        ),
                        const SizedBox(height: 4),
                        _Divider(),
                        const SizedBox(height: 4),
                      ],

                      // OPERATIONS — expenses only; hidden when module is off or no permission
                      if (!isRestrictedEmployee &&
                          permService.isModuleEnabled('expenses')) ...[
                        _SectionLabel('OPERATIONS'),
                        _DrawerTile(
                          icon: IconlyLight.wallet,
                          label: 'Expenses',
                          onTap: () => _pushFullPage(const ExpensesPage()),
                        ),
                        const SizedBox(height: 4),
                        _Divider(),
                        const SizedBox(height: 4),
                      ],

                      // INVENTORY — ingredients management, independent module gate
                      if (permService.can(PermissionKeys.navRecipes) &&
                          permService.isModuleEnabled('ingredients')) ...[
                        _SectionLabel('INVENTORY'),
                        _DrawerTile(
                          icon: IconlyLight.category,
                          label: 'Ingredients',
                          onTap: () => _navigate(AppRoutes.ingredients),
                        ),
                        const SizedBox(height: 4),
                        _Divider(),
                        const SizedBox(height: 4),
                      ],

                      // ADMIN
                      if (canSeeEmployees ||
                          canSeeAuditLogs ||
                          (kShowAiAndFraudNav && canSeeFraud)) ...[
                        _SectionLabel('ADMIN'),
                        if (canSeeEmployees)
                          _DrawerTile(
                            icon: IconlyLight.profile,
                            label: 'Employees',
                            onTap: () => _pushFullPage(const EmployeesPage()),
                          ),
                        // Both go through GoRouter so the router's entitlement
                        // guard actually applies. Audit Logs used to bypass it
                        // via _pushFullPage, which let Starter open a Growth-only
                        // screen on mobile while the desktop sidebar refused.
                        if (canSeeAuditLogs)
                          _DrawerTile(
                            icon: IconlyLight.shield_done,
                            label: 'Audit Logs',
                            lockedPlan: auditLogsLock,
                            onTap: () => _navigate(AppRoutes.auditLogs),
                          ),
                        if (kShowAiAndFraudNav && canSeeFraud)
                          _DrawerTile(
                            icon: IconlyLight.shield_fail,
                            label: 'Unusual Activity',
                            lockedPlan: fraudLock,
                            onTap: () => _navigate(AppRoutes.fraud),
                          ),
                        const SizedBox(height: 4),
                        _Divider(),
                        const SizedBox(height: 4),
                      ],

                      // ACCOUNT — profile tile for cashier/inventory staff only
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

                      // SETTINGS — opens the dedicated Settings page
                      if (!isRestrictedEmployee) ...[
                        _SectionLabel('SETTINGS'),
                        _DrawerTile(
                          icon: IconlyLight.setting,
                          label: 'Settings',
                          onTap: () => _navigate(AppRoutes.settings),
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
            const SizedBox(width: 8),
            // Closes the drawer itself before pushing — PlanBadge's default
            // tap would otherwise stack Billing behind the still-open drawer.
            PlanBadge(
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.billing);
              },
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

  /// Plan code required to actually open this destination, or null when the
  /// current plan includes it. When set the tile stays visible but wears a
  /// [PlanLockBadge] and taps open the upgrade sheet instead of navigating —
  /// never a visible control wired to a guard it can't pass.
  final String? lockedPlan;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.lockedPlan,
  });

  @override
  Widget build(BuildContext context) {
    final locked = lockedPlan != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: locked
            ? () {
                Navigator.of(context).pop(); // close drawer first
                showUpgradePrompt(
                  context,
                  UpgradeMoment.lockedModule,
                  requiredPlan: lockedPlan,
                  // The title names the tier; the body says what they get.
                  detail:
                      'Upgrade to turn on $label — your current work is never '
                      'blocked.',
                );
              }
            : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: locked ? AppColors.textMuted : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: locked
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (locked)
                  PlanLockBadge(planCode: lockedPlan!)
                else
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
