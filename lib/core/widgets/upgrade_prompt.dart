import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/core/widgets/crown_icon.dart';

/// The single, reusable, dismissible upgrade prompt (design §4.3/§4.7).
///
/// One place for every contextual upsell so the anti-patterns in §4.7 are
/// auditable at a glance: always dismissible, shows the concrete unlock plus
/// framing, and NEVER blocks the current action — callers show it *after*
/// letting the action complete (or after a soft cap-check), never mid-sale.
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

_Copy _copyFor(UpgradeMoment m, {String? detail, String? requiredPlan}) {
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
        // Lead with the answer. "This is a paid feature" restates the obstacle
        // the merchant just hit; naming the tier tells them what fixes it.
        requiredPlan == null
            ? 'This is a paid feature'
            : 'Included in ${planLabelOf(requiredPlan)}',
        detail ??
            'Upgrade to unlock this — your current work is never blocked.',
        'Upgrade',
      );
  }
}

/// Shows the upgrade prompt. Returns when dismissed. Never blocks anything —
/// call it after the triggering action, not before.
///
/// [requiredPlan] is the plan code that unlocks the thing they just tried to
/// use. Optional because only [UpgradeMoment.lockedModule] can actually know it
/// (via `requiredPlanFor`) — working out the next tier up for a branch or seat
/// cap needs the plan catalogue, which isn't available offline. When absent the
/// title falls back to its generic form and nothing else changes.
Future<void> showUpgradePrompt(
  BuildContext context,
  UpgradeMoment moment, {
  String? detail,
  String? requiredPlan,
}) {
  final copy = _copyFor(moment, detail: detail, requiredPlan: requiredPlan);
  // Grab the router now, while we certainly have a live context. Several
  // callers (the drawer especially) pop themselves before opening this, so
  // neither their context nor the modal's can be trusted to still be mounted by
  // the time the CTA is pressed.
  final router = GoRouter.of(context);
  // Adaptive: a sheet on phones, a centred dialog on tablet/desktop, where a
  // panel sliding up from the bottom edge of a wide screen feels wrong.
  return showAppModal<void>(
    context: context,
    builder: (_) => _UpgradeSheet(copy: copy, router: router),
  );
}

class _UpgradeSheet extends StatelessWidget {
  final _Copy copy;
  final GoRouter router;

  const _UpgradeSheet({required this.copy, required this.router});

  @override
  Widget build(BuildContext context) {
    final isDialog = AppModalPresentation.isDialogOf(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: isDialog
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: isDialog ? 24 : 8,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDialog) ...[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // The one crown. Gold is the accent here and nowhere else in the
            // sheet — repeating it (hero + pill + button) spends the signal.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.premiumSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const CrownIcon(size: 22, color: AppColors.premium),
            ),
            const SizedBox(height: 16),

            Text(
              copy.title,
              style: getOutfitStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.body,
              style: getOutfitStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Brand blue, like every other primary action. A gold button would
            // make the accent compete with the thing it's meant to sell.
            AppFilledButton(
              label: copy.cta,
              onPressed: () {
                Navigator.of(context).pop();
                router.push(AppRoutes.billing);
              },
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Not now',
                  style: getOutfitStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
