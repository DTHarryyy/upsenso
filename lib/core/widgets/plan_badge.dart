import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/app_status_badge.dart';

/// The business's current subscription tier, as a small pill — for the
/// drawer (mobile) and sidebar (tablet/desktop) headers. Colour carries the
/// account's health so the same "Growth" label reads differently on a trial
/// vs. past due.
///
/// Reads [EntitlementService] directly and repaints on [entitlementRevision]
/// so it stays live with zero cubit, matching [BackupStatusIndicator]'s wiring.
class PlanBadge extends StatelessWidget {
  /// Overrides the default tap behaviour (push straight to Billing). Hosts
  /// that need to do something first — e.g. the mobile drawer closing itself
  /// before navigating — pass their own handler here.
  final VoidCallback? onTap;

  const PlanBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final entitlement = sl<EntitlementService>();
    return ValueListenableBuilder<int>(
      valueListenable: entitlement.entitlementRevision,
      builder: (context, _, _) {
        final status = entitlement.effectiveStatus;
        // A lapsed account is back on Free, not still labelled its old paid
        // tier — matches the "current plan" rule the billing page uses.
        final code = status == 'lapsed' ? 'free' : entitlement.planCode;
        final badge = AppStatusBadge(
          label: planLabelOf(code),
          color: _colorFor(status),
        );

        final canOpenBilling =
            sl<PermissionService>().can(PermissionKeys.navBilling);
        if (!canOpenBilling) return badge;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap ?? () => context.push(AppRoutes.billing),
          child: badge,
        );
      },
    );
  }

  Color _colorFor(String status) => switch (status) {
        'active' => AppColors.brand,
        'trialing' => AppColors.info,
        // Still on the plan, but we haven't been able to confirm it.
        'past_due' || 'unverified' => AppColors.warning,
        'lapsed' => AppColors.error,
        _ => AppColors.textMuted,
      };
}
