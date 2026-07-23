import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/app_filled_button.dart';

/// The single, reusable, dismissible upgrade prompt (design §4.3/§4.7).
///
/// One place for every contextual upsell so the anti-patterns in §4.7 are
/// auditable at a glance: it is a bottom sheet (never a launch popup), always
/// dismissible, shows the concrete unlock + framing, and NEVER blocks the
/// current action — callers show it *after* letting the action complete (or
/// after a soft cap-check), never mid-sale.
///
/// The five real need-moments (§4.3):
///   - 2nd device on Free            → UpgradeMoment.secondDevice
///   - add a branch at cap           → UpgradeMoment.branchCap
///   - own-device seat invite at cap → UpgradeMoment.seatCap
///   - accumulated real data         → UpgradeMoment.dataAccumulated
///   - tap a tier-locked module      → UpgradeMoment.lockedModule
enum UpgradeMoment {
  secondDevice,
  branchCap,
  seatCap,
  dataAccumulated,
  lockedModule,
}

class _Copy {
  final String title;
  final String body;
  final String cta;
  const _Copy(this.title, this.body, this.cta);
}

_Copy _copyFor(UpgradeMoment m, {String? detail}) {
  switch (m) {
    case UpgradeMoment.secondDevice:
      return const _Copy(
        'Sell on all your devices',
        'Turn on cloud to use your phone and your tablet together — from ₱6.50/day.',
        'See plans',
      );
    case UpgradeMoment.branchCap:
      return const _Copy(
        'Running a second location?',
        'Growth connects your branches so stock and sales stay in sync.',
        'Upgrade',
      );
    case UpgradeMoment.seatCap:
      return const _Copy(
        'Give your staff their own login',
        'Upgrade to add another team member so they can sign in on their own '
            'device.',
        'See plans',
      );
    case UpgradeMoment.dataAccumulated:
      return _Copy(
        'Back up your business',
        detail ??
            'You\'ve recorded real sales — all on this one device. Back it up '
                'so you never lose it.',
        'Protect my data',
      );
    case UpgradeMoment.lockedModule:
      return _Copy(
        'This is a paid feature',
        detail ??
            'Upgrade to unlock this — your current work is never blocked.',
        'See what\'s included',
      );
  }
}

/// Shows the upgrade prompt. Returns when dismissed. Never blocks anything —
/// call it after the triggering action, not before.
Future<void> showUpgradePrompt(
  BuildContext context,
  UpgradeMoment moment, {
  String? detail,
}) {
  final copy = _copyFor(moment, detail: detail);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      size: 19, color: AppColors.brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    copy.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              copy.body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppFilledButton(
              label: copy.cta,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.billing);
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Not now'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
