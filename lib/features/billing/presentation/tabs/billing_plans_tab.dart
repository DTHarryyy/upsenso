import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/domain/plan_ladder.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';
import 'package:pos/features/billing/presentation/widgets/billing_period_toggle.dart';
import 'package:pos/features/billing/presentation/widgets/current_plan_card.dart';
import 'package:pos/features/billing/presentation/widgets/plan_card.dart';
import 'package:pos/features/billing/presentation/widgets/plan_cards_skeleton.dart';
import 'package:pos/features/billing/presentation/widgets/upgrade_plans_sheet.dart';

/// Plan surface. Two shapes, depending on whether the tenant is paying:
///
///  * **Subscribed** → a single summary card (what you have, how to cancel),
///    with any tier above it reachable through the upgrade sheet. A grid of
///    buyable cards is noise once you've bought.
///  * **Not subscribed** → the plan ladder, billing-period toggle and all.
///
/// Owns the monthly-vs-annual toggle — nothing outside this tab reads it.
class BillingPlansTab extends StatefulWidget {
  const BillingPlansTab({super.key});

  @override
  State<BillingPlansTab> createState() => _BillingPlansTabState();
}

class _BillingPlansTabState extends State<BillingPlansTab> {
  /// Statuses in which Google Play holds a live subscription for this tenant.
  /// `past_due` belongs here: the plan is still theirs while Google retries.
  /// `unverified` too — we simply haven't reached the server to confirm, and
  /// showing them a buy-again ladder for a plan they're already paying for is
  /// the worst possible guess.
  static const _payingStatuses = {'active', 'past_due', 'unverified'};

  bool _annual = false;

  bool get _canManage =>
      sl<PermissionService>().can(PermissionKeys.billingManage);

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// Android buys through Google Play; other platforms are read-only and point
  /// the user to the Android app.
  void _onSelectPlan(BuildContext context, bool playSupported, PlanOption plan) {
    final cubit = context.read<BillingCubit>();
    if (playSupported) {
      cubit.buyPlan(plan.code, _annual ? 'annual' : 'monthly');
    } else {
      _snack('Subscriptions are managed in the Upsenso Android app.');
    }
  }

  /// Is Play billing this tenant right now?
  bool _isSubscribed(BillingState s) =>
      _payingStatuses.contains(s.effectiveStatus) && s.planCode != 'free';

  /// The legacy price this tenant is actually locked into for [plan], or null.
  ///
  /// `grandfathered_price` lives on the subscription row and outlives the
  /// subscription itself, so reading it raw put a lapsed Growth tenant's "₱499"
  /// on the Free card. A lock only means something when they are paying, for
  /// this exact tier, at less than it costs today.
  double? _lockedPriceFor(PlanOption plan, BillingState s) {
    final locked = s.grandfatheredPrice;
    if (locked == null || locked <= 0) return null;
    if (plan.priceMonthly <= 0) return null;
    if (plan.code != s.planCode) return null;
    if (!_payingStatuses.contains(s.effectiveStatus)) return null;
    return locked < plan.priceMonthly ? locked : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingCubit, BillingState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<BillingCubit>().refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [_planSection(context, state)],
          ),
        );
      },
    );
  }

  Widget _planSection(BuildContext context, BillingState s) {
    // A subscriber's summary comes from the cached entitlement, so it renders
    // offline — only the ladder needs the catalog.
    if (_isSubscribed(s)) return _summary(s);

    if (s.offline) {
      return _noticeCard(
        icon: Icons.wifi_off_rounded,
        text: 'You\'re offline. Connect to change your plan — selling and '
            'everything on this device keeps working.',
      );
    }
    if (s.catalogFailed) {
      return _noticeCard(
        icon: Icons.cloud_off_rounded,
        text: 'Couldn\'t load plans right now.',
        action: OutlinedButton.icon(
          onPressed: () => context.read<BillingCubit>().refresh(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Try again'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!s.playSupported) ...[
          const AppInlineBanner(
            message: 'Subscriptions are managed in the Upsenso Android app. '
                'Here you can review your plan and usage anytime.',
            variant: AppInlineBannerVariant.info,
          ),
          const SizedBox(height: 16),
        ],
        // Say why a plan can't be bought here, rather than only at the moment
        // the user taps Upgrade and gets a dead end.
        if (s.playSupported && s.storeNotice != null) ...[
          AppInlineBanner(
            message: s.storeNotice!,
            variant: AppInlineBannerVariant.warning,
          ),
          const SizedBox(height: 16),
        ],
        Center(
          child: BillingPeriodToggle(
            annual: _annual,
            onChanged: (v) => setState(() => _annual = v),
          ),
        ),
        const SizedBox(height: 24),
        // Placeholders rather than a "Loading plans…" line: the real cards land
        // in the space these already occupy, so nothing jumps.
        if (s.plans.isEmpty)
          const PlanCardsSkeleton(count: 3) // the live catalog is Free/Starter/Growth
        else
          _planCards(context, s),
        if (s.restoreInProgress) ...[
          const SizedBox(height: 16),
          _mutedLine('Checking your Google Play purchases…', center: true),
        ],
      ],
    );
  }

  // ── Subscribed summary ──────────────────────────────────────────────────────
  Widget _summary(BillingState s) {
    // Null offline — the nudge needs the catalog to name where you'd be going,
    // and offline you couldn't buy anyway.
    final current = planOfCode(s.plans, s.planCode);
    final above = current == null ? const <PlanOption>[] : tiersAbove(s.plans, current);

    return CurrentPlanCard(
      planCode: s.planCode,
      effectiveStatus: s.effectiveStatus,
      currentPlan: current,
      nextTier: above.isEmpty ? null : above.first,
      lockedPrice: current == null ? null : _lockedPriceFor(current, s),
      renewsOn: s.renewsOn,
      ownedProductId: s.ownedProductId,
      playSupported: s.playSupported,
      canManage: _canManage,
      onUpgrade: () => _openUpgradeSheet(context, current!),
    );
  }

  void _openUpgradeSheet(BuildContext context, PlanOption current) {
    final cubit = context.read<BillingCubit>();
    showAppModal<void>(
      context: context,
      builder: (_) => BlocProvider<BillingCubit>.value(
        value: cubit,
        child: UpgradePlansSheet(
          currentPlan: current,
          annual: _annual,
          canManage: _canManage,
        ),
      ),
    );
  }

  // ── Ladder ──────────────────────────────────────────────────────────────────
  Widget _planCards(BuildContext context, BillingState s) {
    // A lapsed or never-subscribed account lives on Free — mark that card so
    // the tab always shows where you are. Trialing tenants reach this too, and
    // for them planCode is the tier they're trialling.
    final currentCode =
        (s.effectiveStatus == 'free' || s.effectiveStatus == 'lapsed')
            ? 'free'
            : s.planCode;
    final plans = s.plans;
    final currentPlan = planOfCode(plans, currentCode);
    // The middle tier gets the "Most Popular" spotlight (like the reference
    // layout) — indexed over the tiers actually rendered, or dropping Free
    // would shift the badge onto the wrong card.
    final recommendedIndex = plans.length ~/ 2;
    final lastIndex = plans.length - 1;

    PlanCard card(int i) {
      final plan = plans[i];
      return PlanCard(
        plan: plan,
        previousTier: i > 0 ? plans[i - 1] : null,
        currentPlan: currentPlan,
        annual: _annual,
        isCurrent: plan.code == currentCode,
        isRecommended: i == recommendedIndex,
        leadWithEverything: i == lastIndex && i > 0,
        busy: s.purchaseInProgress,
        canManage: _canManage,
        // No lock chip here: only non-subscribers reach this ladder, and a lock
        // only ever applies to a tier you're actively paying for.
        onSelect: () => _onSelectPlan(context, s.playSupported, plan),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720 && plans.length > 1;
        if (!wide) {
          return Column(
            children: [
              for (int i = 0; i < plans.length; i++) ...[
                card(i),
                if (i != lastIndex) const SizedBox(height: 16),
              ],
            ],
          );
        }
        // Side by side, top-aligned — the popular card sits taller by design.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < plans.length; i++) ...[
              Expanded(child: card(i)),
              if (i != lastIndex) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _mutedLine(String text, {bool center = false}) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
        fontSize: 12,
        height: 1.4,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _noticeCard(
      {required IconData icon, required String text, Widget? action}) {
    return AppSectionCard(
      title: 'Plans',
      icon: Icons.workspace_premium_rounded,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                    fontSize: 13, height: 1.4, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        if (action != null) ...[const SizedBox(height: 12), action],
      ],
    );
  }

}
