import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/domain/plan_ladder.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';
import 'package:pos/features/billing/presentation/widgets/billing_period_toggle.dart';
import 'package:pos/features/billing/presentation/widgets/plan_card.dart';
import 'package:pos/features/billing/presentation/widgets/plan_cards_skeleton.dart';

/// Where a subscriber goes to move up: only the tiers above the one they hold.
///
/// Their own tier and everything below it is deliberately absent — someone who
/// has already bought is asking "what's above me", and a full ladder makes them
/// find that out for themselves.
class UpgradePlansSheet extends StatefulWidget {
  final PlanOption currentPlan;

  /// Seeded from the tab's toggle so the sheet opens on the period they were
  /// already looking at.
  final bool annual;

  /// Resolved by the caller — keeps the service locator out of this widget.
  final bool canManage;

  const UpgradePlansSheet({
    super.key,
    required this.currentPlan,
    required this.annual,
    required this.canManage,
  });

  @override
  State<UpgradePlansSheet> createState() => _UpgradePlansSheetState();
}

class _UpgradePlansSheetState extends State<UpgradePlansSheet> {
  late bool _annual = widget.annual;

  /// Close before handing off to Play. The billing page surfaces purchase
  /// errors as snackbars, which would render behind this sheet and be missed —
  /// and a sheet still offering the tier they just bought reads as a failure.
  void _select(BuildContext context, PlanOption plan) {
    final cubit = context.read<BillingCubit>();
    Navigator.of(context).pop();
    cubit.buyPlan(plan.code, _annual ? 'annual' : 'monthly');
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title: 'Upgrade your plan',
      child: BlocBuilder<BillingCubit, BillingState>(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: _body(context, state),
        ),
      ),
    );
  }

  // Same precedence as the plan ladder, so the two surfaces never disagree
  // about why plans aren't showing.
  Widget _body(BuildContext context, BillingState s) {
    if (s.offline) {
      return const _Notice(
        'You\'re offline. Reconnect to change your plan — selling and '
        'everything on this device keeps working.',
      );
    }
    if (s.catalogFailed) {
      return _Notice(
        'Couldn\'t load plans right now.',
        action: OutlinedButton.icon(
          onPressed: () => context.read<BillingCubit>().refresh(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Try again'),
        ),
      );
    }
    // Defensive: the nudge that opens this sheet already needed a resolved
    // catalog, and the cubit keeps the cached list through a failed refresh.
    if (s.plans.isEmpty) return const PlanCardsSkeleton(count: 2);

    final higher = tiersAbove(s.plans, widget.currentPlan);
    // Guards the race where a purchase lands while the sheet is open.
    if (higher.isEmpty) {
      return const _Notice('You\'re on our top plan — there\'s nothing above it.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: BillingPeriodToggle(
            annual: _annual,
            onChanged: (v) => setState(() => _annual = v),
          ),
        ),
        const SizedBox(height: 24),
        _cards(context, s, higher),
        const SizedBox(height: 16),
        Text(
          'Upgrades start right away and Google credits your unused time.',
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _cards(BuildContext context, BillingState s, List<PlanOption> higher) {
    final lastIndex = higher.length - 1;
    return Column(
      children: [
        for (int i = 0; i < higher.length; i++) ...[
          PlanCard(
            plan: higher[i],
            // The first card's "previous" is the tenant's own tier, so
            // "Everything in Starter" is literally true for whoever reads it.
            previousTier: i == 0 ? widget.currentPlan : higher[i - 1],
            currentPlan: widget.currentPlan,
            annual: _annual,
            isCurrent: false,
            // The immediate next step is what we steer to, and this keeps
            // exactly one filled card at the top of the sheet.
            isRecommended: i == 0,
            // Every card here sits above something the tenant already owns, so
            // the delta framing is the honest, compact one.
            leadWithEverything: true,
            busy: s.purchaseInProgress,
            canManage: widget.canManage,
            onSelect: () => _select(context, higher[i]),
          ),
          if (i != lastIndex) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Notice(this.text, {this.action});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInlineBanner(message: text, variant: AppInlineBannerVariant.info),
        ?action,
      ],
    );
  }
}
