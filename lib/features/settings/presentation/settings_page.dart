import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/app_switch.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/core/widgets/settings_tile.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';

/// The app's dedicated Settings page. Replaces the old drawer/sidebar dropdown.
///
/// Reached via `context.push(AppRoutes.settings)` so it stacks as a poppable
/// sub-page with the shared [AppSubPageBar] back button (see
/// `main_navigation_page.dart` `isStackedSubPage`).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final perms = sl<PermissionService>();
    // Owners/admins configure the whole business; refund-approvers set their PIN.
    final canEditBusiness = perms.can(PermissionKeys.settingsEditBusiness);
    final canApproveRefund = perms.can(PermissionKeys.posApproveRefund);
    final canSeeBilling = perms.can(PermissionKeys.navBilling);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppSubPageBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Account ──────────────────────────────────────────────────────
          SettingsSection(
            label: 'Account',
            children: [
              SettingsTile(
                icon: IconlyLight.profile,
                title: 'My Profile',
                showChevron: true,
                onTap: () => context.push(AppRoutes.profile),
              ),
              if (canSeeBilling)
                SettingsTile(
                  icon: IconlyLight.wallet,
                  title: 'Billing & Subscription',
                  showChevron: true,
                  onTap: () => context.push(AppRoutes.billing),
                ),
              SettingsTile(
                icon: IconlyLight.download,
                title: 'Export My Data',
                showChevron: true,
                onTap: () => context.push(AppRoutes.dataExport),
              ),
            ],
          ),

          // ── Business ─────────────────────────────────────────────────────
          SettingsSection(
            label: 'Business',
            children: [
              SettingsTile(
                icon: IconlyLight.work,
                title: 'Business Profile',
                showChevron: true,
                onTap: () => context.push(AppRoutes.businessProfile),
              ),
              SettingsTile(
                icon: IconlyLight.paper,
                title: 'Receipt Settings',
                subtitle: 'Logo, paper size, tax, header & footer',
                showChevron: true,
                onTap: () => context.push(AppRoutes.receiptSettings),
              ),
              // Admin-only bundle (modules, refund approval, manager PIN) lives
              // on its own page; the row hides entirely for non-admins.
              if (canEditBusiness || canApproveRefund)
                SettingsTile(
                  icon: IconlyLight.setting,
                  title: 'System Settings',
                  subtitle: 'Modules, refund approval, manager PIN',
                  showChevron: true,
                  onTap: () => context.push(AppRoutes.systemSettings),
                ),
            ],
          ),

          // ── General (moved below the business/account settings) ──────────
          SettingsSection(
            label: 'General',
            children: [
              SettingsTile(
                icon: IconlyLight.swap,
                title: 'Switch themes',
                // TODO(settings): wire sl<ThemeController>().toggleDarkMode()
                // once the app-wide dark theme is ready (most screens still use
                // static AppColors, so a real toggle wouldn't restyle them yet).
                trailing: AppSwitch(
                  value: false,
                  onChanged: (_) => _comingSoon(context),
                ),
                onTap: () => _comingSoon(context),
              ),
              SettingsTile(
                icon: IconlyLight.delete,
                title: 'Clear cache',
                // TODO(settings): implement cache clearing.
                onTap: () => _comingSoon(context),
              ),
              SettingsTile(
                icon: IconlyLight.chat,
                title: 'Leave feedback',
                subtitle: 'Help us make the app better',
                // TODO(settings): implement in-app feedback flow.
                onTap: () => _comingSoon(context),
              ),
              SettingsTile(
                icon: IconlyLight.info_circle,
                title: 'FAQ',
                showChevron: true,
                // TODO(settings): implement FAQ page.
                onTap: () => _comingSoon(context),
              ),
            ],
          ),

          // ── Legal (shown, not wired yet) ─────────────────────────────────
          SettingsSection(
            label: 'Legal',
            children: [
              SettingsTile(
                icon: IconlyLight.shield_done,
                title: 'Data Privacy Terms',
                showChevron: true,
                // TODO(settings): wire the Data Privacy page/route once it exists.
                onTap: () => _comingSoon(context),
              ),
              SettingsTile(
                icon: IconlyLight.document,
                title: 'Terms and Conditions',
                showChevron: true,
                // TODO(settings): wire the Terms & Conditions page/route.
                onTap: () => _comingSoon(context),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _SignOutTile(onSignOut: () => _confirmSignOut(context)),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    AppToast.show(context, 'Coming soon', variant: AppToastVariant.info);
  }

  void _confirmSignOut(BuildContext context) {
    // Capture the bloc before the async gap so we never touch a stale context.
    final authBloc = context.read<AuthBloc>();
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign out?',
          style: getOutfitStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
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
              'Sign out',
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
      if (confirm == true) authBloc.add(AuthLogoutRequested());
    });
  }
}

// ── Sign out: standalone row (no card), matches the reference ───────────────

class _SignOutTile extends StatelessWidget {
  final VoidCallback onSignOut;

  const _SignOutTile({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSignOut,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(
                IconlyLight.logout,
                size: 22,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 16),
              Text(
                'Sign out',
                style: getOutfitStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
