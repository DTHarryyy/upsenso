import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/features/billing/presentation/widgets/active_branch_chooser_sheet.dart';

/// Persistent strip stating that the business is holding more branches or staff
/// than the plan covers, with the one tap that fixes it.
///
/// Deliberately not dismissible: this is a standing condition, not an event.
/// It disappears the moment the tenant is back under cap or upgrades — nothing
/// here ever needs acknowledging, because acknowledging wouldn't change it.
class OverCapBanner extends StatelessWidget {
  const OverCapBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final enforcement = sl<EntitlementEnforcementService>();
    return ValueListenableBuilder<int>(
      valueListenable: enforcement.lockRevision,
      builder: (context, _, _) {
        if (!enforcement.hasOverCapResources) return const SizedBox.shrink();

        final branches = enforcement.lockedBranchIds.length;
        final seats = enforcement.suspendedEmployeeIds.length;
        final plan = planLabelOf(sl<EntitlementService>().planCode);
        final parts = [
          if (branches > 0)
            '$branches ${branches == 1 ? 'branch' : 'branches'}',
          if (seats > 0) '$seats ${seats == 1 ? 'person' : 'people'}',
        ].join(' and ');

        // Only someone who can act on it gets the action.
        final canManage = sl<PermissionService>().can(
          PermissionKeys.billingManage,
        );

        return Material(
          color: AppColors.warningSoft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$parts above your $plan plan — kept safe, but read-only.',
                    style: getOutfitStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
                if (canManage) ...[
                  if (branches > 0)
                    TextButton(
                      onPressed: () => ActiveBranchChooserSheet.show(context),
                      style: _compact,
                      child: Text('Choose', style: _actionStyle),
                    ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.billing),
                    style: _compact,
                    child: Text('Upgrade', style: _actionStyle),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static final ButtonStyle _compact = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  static TextStyle get _actionStyle => getOutfitStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: AppColors.warning,
  );
}
