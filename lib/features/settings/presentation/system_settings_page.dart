import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/widgets/app_empty_state.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/settings_tile.dart';

/// Business-admin configuration, grouped off the main Settings page.
///
/// Holds Module Management + Refund Approval (owner/admin) and Manager PIN
/// (refund approvers). Each row keeps its own permission gate; the whole page
/// is reached from the "System Settings" row in Settings → Business, which is
/// itself hidden unless the user can see at least one of these.
class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final perms = sl<PermissionService>();
    final canEditBusiness = perms.can(PermissionKeys.settingsEditBusiness);
    final canApproveRefund = perms.can(PermissionKeys.posApproveRefund);

    final rows = <Widget>[
      if (canEditBusiness) ...[
        SettingsTile(
          icon: IconlyLight.category,
          title: 'Module Management',
          subtitle: 'Enable or disable features for your business',
          showChevron: true,
          onTap: () {
            final businessId = sl<ActiveBusinessContext>().businessId ?? '';
            context.push(AppRoutes.moduleSettings, extra: businessId);
          },
        ),
        SettingsTile(
          icon: IconlyLight.tick_square,
          title: 'Refund Approval',
          subtitle: 'Require a manager PIN for over-limit refunds',
          showChevron: true,
          onTap: () => context.push(AppRoutes.refundApprovalSettings),
        ),
      ],
      if (canApproveRefund)
        SettingsTile(
          icon: IconlyLight.lock,
          title: 'Manager PIN',
          subtitle: 'Set the PIN you use to authorise refunds',
          showChevron: true,
          onTap: () => context.push(AppRoutes.managerPin),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppSubPageBar(title: 'System Settings'),
      // Deep-linking here without the underlying permissions is possible, so
      // guard against an empty page rather than showing a bare card.
      body: rows.isEmpty
          ? const AppEmptyState(
              icon: IconlyLight.lock,
              title: 'Nothing to configure',
              message: 'You don\'t have access to any system settings.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [SettingsSection(children: rows)],
            ),
    );
  }
}
