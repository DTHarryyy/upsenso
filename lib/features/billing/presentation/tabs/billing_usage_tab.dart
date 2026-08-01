import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/widgets/app_empty_state.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';
import 'package:pos/features/billing/presentation/widgets/active_branch_chooser_sheet.dart';
import 'package:pos/features/billing/presentation/widgets/usage_meter.dart';

/// Branches / team members / devices vs. plan caps.
///
/// Shown whenever any cap is known, regardless of tier — Free's caps (1
/// branch / 2 seats / 1 device) are real and server-enforced too, and seeing
/// them is exactly what motivates an upgrade.
class BillingUsageTab extends StatelessWidget {
  const BillingUsageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingCubit, BillingState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<BillingCubit>().refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const _OverCapCard(),
              if (_hasLimits(state))
                _usageCard(state)
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: AppEmptyState(
                    icon: Icons.speed_outlined,
                    title: 'No limits to show',
                    message: 'Your plan has no usage caps right now.',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _hasLimits(BillingState s) =>
      s.maxBranches != null || s.maxSeats != null || s.maxDevices != null;

  Widget _usageCard(BillingState s) {
    return AppSectionCard(
      title: 'Usage',
      icon: Icons.speed_outlined,
      children: [
        UsageMeter(label: 'Branches', used: s.branchUsage, max: s.maxBranches),
        const SizedBox(height: 14),
        UsageMeter(label: 'Team members', used: s.seatUsage, max: s.maxSeats),
        const SizedBox(height: 14),
        UsageMeter(label: 'Devices', used: s.deviceUsage, max: s.maxDevices),
      ],
    );
  }
}

/// What's currently held above the plan, and the one control that changes it.
///
/// The meters above go red at the cap but can't say what happened to the
/// overflow — this does, and it's the only place an owner can re-pick which
/// branches stay open after a downgrade.
class _OverCapCard extends StatelessWidget {
  const _OverCapCard();

  @override
  Widget build(BuildContext context) {
    final enforcement = sl<EntitlementEnforcementService>();
    return ValueListenableBuilder<int>(
      valueListenable: enforcement.lockRevision,
      builder: (context, _, _) {
        if (!enforcement.hasOverCapResources) return const SizedBox.shrink();
        final branches = enforcement.lockedBranchIds.length;
        final seats = enforcement.suspendedEmployeeIds.length;
        final canManage = sl<PermissionService>().can(
          PermissionKeys.billingManage,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppSectionCard(
            title: 'Above your plan',
            icon: Icons.lock_outline_rounded,
            children: [
              Text(
                'Nothing has been deleted. These stay readable and keep every '
                'record they already hold — they just can\'t be sold on or '
                'signed into until your plan covers them again.',
                style: getOutfitStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              if (branches > 0)
                _OverCapRow(
                  label: '$branches ${branches == 1 ? 'branch' : 'branches'} '
                      'read-only',
                  actionLabel: canManage ? 'Choose which' : null,
                  onAction: () => ActiveBranchChooserSheet.show(context),
                ),
              if (seats > 0)
                _OverCapRow(
                  label: '$seats ${seats == 1 ? 'person needs' : 'people need'} '
                      'a seat',
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OverCapRow extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _OverCapRow({required this.label, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: getOutfitStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
