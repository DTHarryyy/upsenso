import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_skeleton.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/data/iap_service.dart';
import 'package:pos/features/billing/data/play_purchase_sync_service.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';
import 'package:pos/features/billing/presentation/widgets/plan_card.dart';
import 'package:pos/features/billing/presentation/widgets/usage_meter.dart';

/// Billing & subscription. The page opens straight into the plan picker — the
/// current tier is marked inside its card, and a slim banner appears only when
/// the account needs attention (trial, past due, paused, offline). Purchases
/// require a connection; everything else renders offline-first.
class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BillingCubit>(
      create: (_) => BillingCubit(
        entitlement: sl<EntitlementService>(),
        remoteDs: sl<BillingRemoteDs>(),
        connectivity: sl<ConnectivityService>(),
        deviceRegistration: sl(),
        iap: sl<IapService>(),
        purchaseSync: sl<PlayPurchaseSyncService>(),
        activeBusiness: sl<ActiveBusinessContext>(),
      )..load(),
      child: const _BillingView(),
    );
  }
}

class _BillingView extends StatefulWidget {
  const _BillingView();

  @override
  State<_BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends State<_BillingView>
    with WidgetsBindingObserver {
  bool _annual = false;

  bool get _canManage =>
      sl<PermissionService>().can(PermissionKeys.billingManage);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On resume, pull the fresh plan so a just-completed purchase (or a change
    // made elsewhere) reflects immediately.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<BillingCubit>().refresh();
    }
  }

  /// Android buys through Google Play; other platforms are read-only and point
  /// the user to the Android app.
  void _onSelectPlan(BuildContext context, PlanOption plan) {
    final cubit = context.read<BillingCubit>();
    if (cubit.state.playSupported) {
      cubit.buyPlan(plan.code, _annual ? 'annual' : 'monthly');
    } else {
      _snack('Subscriptions are managed in the Upsenso Android app.');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Billing & Subscription'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
      ),
      body: BlocConsumer<BillingCubit, BillingState>(
        listenWhen: (prev, curr) =>
            curr.purchaseError != null &&
            curr.purchaseError != prev.purchaseError,
        listener: (context, state) => _snack(state.purchaseError!),
        builder: (context, state) {
          if (state.status == BillingStatus.loading) {
            return const AppSkeletonList(itemCount: 4);
          }
          return RefreshIndicator(
            onRefresh: () => context.read<BillingCubit>().refresh(),
            child: Center(
              child: ConstrainedBox(
                // Keeps the picker readable on web/desktop instead of
                // stretching cards across an ultra-wide window.
                constraints: const BoxConstraints(maxWidth: 1080),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ..._statusBanners(state),
                    _planSection(context, state),
                    if (_showMeters(state)) ...[
                      const SizedBox(height: 16),
                      _usageCard(state),
                    ],
                    if (state.devices.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _devicesCard(context, state),
                    ],
                    if (state.payments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _invoicesCard(state),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Attention banners (replace the old always-on hero) ──────────────────────
  List<Widget> _statusBanners(BillingState s) {
    final banners = <Widget>[];
    final d = s.daysRemaining;
    final (msg, variant) = switch (s.effectiveStatus) {
      'trialing' => (
          d != null
              ? 'Free trial — $d ${_dayWord(d)} left. Cloud backup is on us; '
                  'pick a plan below to keep it.'
              : 'Free trial — cloud backup is on us. Pick a plan below to keep it.',
          AppInlineBannerVariant.info,
        ),
      'past_due' => (
          d != null
              ? 'Payment pending — cloud stays on for $d more ${_dayWord(d)}. '
                  'Your POS keeps working.'
              : 'Payment pending — your POS keeps working.',
          AppInlineBannerVariant.warning,
        ),
      'lapsed' => (
          'Cloud is paused. Your data is safe on this device — reactivate below '
              'anytime.',
          AppInlineBannerVariant.warning,
        ),
      _ => (null, AppInlineBannerVariant.info),
    };
    if (msg != null) {
      banners.add(AppInlineBanner(message: msg, variant: variant));
    }
    if (s.offline) {
      banners.add(const AppInlineBanner(
        message: 'You\'re offline — showing your saved plan. Selling keeps '
            'working; reconnect to change plans.',
        variant: AppInlineBannerVariant.info,
      ));
    }
    return banners;
  }

  String _dayWord(int n) => n == 1 ? 'day' : 'days';

  bool _showMeters(BillingState s) =>
      s.cloudEnabled &&
      (s.maxBranches != null || s.maxSeats != null || s.maxDevices != null);

  // ── Plans section (with offline / retry states) ─────────────────────────────
  Widget _planSection(BuildContext context, BillingState s) {
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
    if (s.plans.isEmpty) {
      return _noticeCard(
          icon: Icons.hourglass_empty_rounded, text: 'Loading plans…');
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
        Center(child: _periodToggle()),
        const SizedBox(height: 24),
        _planCards(context, s),
        if (s.playSupported) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: s.purchaseInProgress
                  ? null
                  : () => context.read<BillingCubit>().restore(),
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: const Text('Restore purchases'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _planCards(BuildContext context, BillingState s) {
    // A lapsed or never-subscribed account lives on Free — mark that card so
    // the page always shows where you are.
    final currentCode =
        (s.effectiveStatus == 'free' || s.effectiveStatus == 'lapsed')
            ? 'free'
            : s.planCode;
    PlanOption? currentPlan;
    for (final p in s.plans) {
      if (p.code == currentCode) currentPlan = p;
    }
    // The middle tier gets the "Most Popular" spotlight (like the reference
    // layout) — it's also our launch conversion tier.
    final recommendedIndex = s.plans.length ~/ 2;
    final lastIndex = s.plans.length - 1;

    PlanCard card(int i) {
      final plan = s.plans[i];
      return PlanCard(
        plan: plan,
        previousTier: i > 0 ? s.plans[i - 1] : null,
        currentPlan: currentPlan,
        annual: _annual,
        isCurrent: plan.code == currentCode,
        isRecommended: i == recommendedIndex,
        leadWithEverything: i == lastIndex && i > 0,
        busy: s.purchaseInProgress,
        canManage: _canManage,
        grandfatheredPrice: s.grandfatheredPrice,
        onSelect: () => _onSelectPlan(context, plan),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720 && s.plans.length > 1;
        if (!wide) {
          return Column(
            children: [
              for (int i = 0; i < s.plans.length; i++) ...[
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
            for (int i = 0; i < s.plans.length; i++) ...[
              Expanded(child: card(i)),
              if (i != lastIndex) const SizedBox(width: 16),
            ],
          ],
        );
      },
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

  /// Pill billing-period toggle — dark brand track with a light active pill and
  /// a "SAVE 17%" chip on the annual side (annual = 10 months, 2 free).
  Widget _periodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _periodSegment(label: 'Bill annually', selected: _annual, badge: 'SAVE 17%', onTap: () => setState(() => _annual = true)),
          _periodSegment(label: 'Bill monthly', selected: !_annual, onTap: () => setState(() => _annual = false)),
        ],
      ),
    );
  }

  Widget _periodSegment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.brandDark : Colors.white70,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brandSoft
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.brandDark : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Usage meters ────────────────────────────────────────────────────────────
  Widget _usageCard(BillingState s) {
    return AppSectionCard(
      title: 'Usage',
      icon: Icons.speed_outlined,
      children: [
        UsageMeter(label: 'Branches', used: s.branchUsage, max: s.maxBranches),
        const SizedBox(height: 14),
        UsageMeter(
            label: 'Team members', used: s.seatUsage, max: s.maxSeats),
        const SizedBox(height: 14),
        UsageMeter(label: 'Devices', used: s.deviceUsage, max: s.maxDevices),
      ],
    );
  }

  // ── Devices ─────────────────────────────────────────────────────────────────
  Widget _devicesCard(BuildContext context, BillingState s) {
    final active = s.devices.where((d) => !d.isRevoked).toList();
    return AppSectionCard(
      title: 'Devices',
      icon: Icons.devices_outlined,
      children: [
        for (final d in active)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(_platformIcon(d.platform),
                      size: 17, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.label,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      if (d.lastSeenAt != null)
                        Text('Last seen ${_date(d.lastSeenAt!)}',
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (_canManage)
                  TextButton(
                    onPressed: s.purchaseInProgress
                        ? null
                        : () => context
                            .read<BillingCubit>()
                            .revokeDevice(d.deviceUid),
                    child: const Text('Revoke'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Invoices ────────────────────────────────────────────────────────────────
  Widget _invoicesCard(BillingState s) {
    return AppSectionCard(
      title: 'Payment history',
      icon: Icons.receipt_long_outlined,
      children: [
        for (final p in s.payments)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_invoiceLabel(p),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(
                        '${_date(p.createdAt)}${p.isTest ? '  ·  test' : ''}',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text('₱${p.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 10),
                _payStatusDot(p.status),
              ],
            ),
          ),
      ],
    );
  }

  Widget _payStatusDot(String status) {
    final color = status == 'paid'
        ? AppColors.success
        : status == 'failed'
            ? AppColors.error
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _invoiceLabel(BillingPayment p) => p.kind == 'addon'
      // Historical add-on purchases still render even though add-ons are gone.
      ? 'Add-on: ${p.addonCode ?? ''}'
      : 'Plan: ${_planLabel(p.planCode ?? 'free')}';

  String _planLabel(String code) => switch (code) {
        'starter' => 'Starter',
        'growth' => 'Growth',
        'business' => 'Business',
        'enterprise' => 'Enterprise',
        _ => 'Free',
      };

  IconData _platformIcon(String platform) => switch (platform) {
        'android' => Icons.android,
        'ios' || 'macos' => Icons.phone_iphone,
        'web' => Icons.language,
        'windows' => Icons.desktop_windows,
        _ => Icons.devices_other,
      };

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
