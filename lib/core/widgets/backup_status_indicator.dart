import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/routes/app_routes.dart';

/// A calm, always-honest backup-status chip (design §4.2).
///
/// Free/local: "Backup: off — on this device only" + one-tap Protect → billing.
/// Cloud tiers: "Backed up ✓". Never a red alarm. Reads EntitlementService and
/// repaints on entitlementRevision so it can live in the app shell / a header.
class BackupStatusIndicator extends StatelessWidget {
  /// When true, the Free state is tappable and routes to billing. Set false
  /// where the surrounding surface already handles the tap.
  final bool tappable;

  const BackupStatusIndicator({super.key, this.tappable = true});

  @override
  Widget build(BuildContext context) {
    final entitlement = sl<EntitlementService>();
    return ValueListenableBuilder<int>(
      valueListenable: entitlement.entitlementRevision,
      builder: (context, _, _) {
        final on = entitlement.cloudEnabled;
        final chip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: on ? AppColors.successSoft : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: on ? AppColors.success : AppColors.borderSoft,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                on ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                size: 14,
                color: on ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                on ? 'Backed up' : 'Backup: off — on this device only',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: on ? AppColors.success : AppColors.textSecondary,
                ),
              ),
              if (!on && tappable) ...[
                const SizedBox(width: 8),
                const Text(
                  'Protect',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ],
          ),
        );

        if (on || !tappable) return chip;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push(AppRoutes.billing),
          child: chip,
        );
      },
    );
  }
}
