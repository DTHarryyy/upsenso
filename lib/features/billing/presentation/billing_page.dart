import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';
import 'package:pos/features/billing/presentation/widgets/plan_card.dart';
import 'package:pos/features/billing/presentation/widgets/usage_meter.dart';

/// Billing & subscription — plan picker (₱/day framing), usage meters, add-ons,
/// registered devices, and invoice history. Current-plan section is offline-
/// first; purchases require a connection.
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
  bool _busy = false;

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
    // Returning from the external PayMongo checkout: pull the fresh plan so a
    // just-completed upgrade reflects immediately.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<BillingCubit>().refresh();
    }
  }

  Future<void> _launch(Future<String> Function() start) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final url = await start();
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack('Could not open the checkout page.');
    } catch (_) {
      if (mounted) _snack('Checkout failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
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
      body: BlocBuilder<BillingCubit, BillingState>(
        builder: (context, state) {
          if (state.status == BillingStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => context.read<BillingCubit>().refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PlanHero(state: state),
                const SizedBox(height: 16),
                if (_showMeters(state)) ...[
                  _usageCard(state),
                  const SizedBox(height: 16),
                ],
                _planSection(context, state),
                if (state.addons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _addonsCard(context, state),
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
          );
        },
      ),
    );
  }

  bool _showMeters(BillingState s) =>
      s.cloudEnabled &&
      (s.maxBranches != null || s.maxSeats != null || s.maxDevices != null);

  // ── Usage meters ────────────────────────────────────────────────────────────
  Widget _usageCard(BillingState s) {
    return AppSectionCard(
      title: 'Usage',
      icon: Icons.speed_outlined,
      children: [
        UsageMeter(label: 'Branches', used: s.branchUsage, max: s.maxBranches),
        const SizedBox(height: 14),
        UsageMeter(label: 'Seats', used: s.seatUsage, max: s.maxSeats),
        const SizedBox(height: 14),
        UsageMeter(label: 'Devices', used: s.deviceUsage, max: s.maxDevices),
      ],
    );
  }

  // ── Plans section (with offline / retry states) ─────────────────────────────
  Widget _planSection(BuildContext context, BillingState s) {
    return AppSectionCard(
      title: 'Plans',
      icon: Icons.grid_view_rounded,
      trailing: s.plans.isNotEmpty ? _periodToggle() : null,
      children: [
        if (s.offline)
          _notice(
            icon: Icons.wifi_off_rounded,
            text: 'You\'re offline. Connect to change your plan — selling and '
                'everything on this device keeps working.',
          )
        else if (s.catalogFailed)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _notice(
                icon: Icons.cloud_off_rounded,
                text: 'Couldn\'t load plans right now.',
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.read<BillingCubit>().refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          )
        else if (s.plans.isEmpty)
          _notice(icon: Icons.hourglass_empty_rounded, text: 'Loading plans…')
        else
          ...[
            for (int i = 0; i < s.plans.length; i++) ...[
              PlanCard(
                plan: s.plans[i],
                annual: _annual,
                isCurrent: s.plans[i].code == s.planCode &&
                    s.effectiveStatus != 'lapsed' &&
                    s.effectiveStatus != 'free',
                isRecommended: s.plans[i].code == 'growth',
                busy: _busy,
                canManage: _canManage,
                onSelect: () => _launch(() => context
                    .read<BillingCubit>()
                    .startPlanCheckout(s.plans[i].code, s.plans[i].version,
                        _annual ? 'annual' : 'monthly')),
              ),
              if (i != s.plans.length - 1) const SizedBox(height: 12),
            ],
          ],
      ],
    );
  }

  Widget _notice({required IconData icon, required String text}) {
    return Row(
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
    );
  }

  Widget _periodToggle() {
    return SegmentedButton<bool>(
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: const [
        ButtonSegment(value: false, label: Text('Monthly')),
        ButtonSegment(value: true, label: Text('Annual')),
      ],
      selected: {_annual},
      onSelectionChanged: (v) => setState(() => _annual = v.first),
    );
  }

  // ── Add-ons ─────────────────────────────────────────────────────────────────
  Widget _addonsCard(BuildContext context, BillingState s) {
    return AppSectionCard(
      title: 'Add-ons',
      icon: Icons.add_circle_outline_rounded,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Grow without changing plans — add just what you need.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        for (final a in s.addons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('₱${a.priceMonthly.toStringAsFixed(0)}/mo',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: (!_canManage || _busy || !s.cloudEnabled)
                      ? null
                      : () => _launch(() => context
                          .read<BillingCubit>()
                          .startAddonCheckout(a.code, 1)),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
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
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(_platformIcon(d.platform),
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(d.label,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary)),
                ),
                if (_canManage)
                  TextButton(
                    onPressed: _busy
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

/// The current-plan hero — the emotional anchor of the page. Tints to the plan
/// state (trial/active = brand, past_due/lapsed = warning, free = neutral) so
/// the situation reads at a glance without alarm.
class _PlanHero extends StatelessWidget {
  final BillingState state;
  const _PlanHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = _theme(state.effectiveStatus);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.$1, theme.$2],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(theme.$3, size: 18, color: theme.$4),
              const SizedBox(width: 8),
              Text(
                'YOUR PLAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: theme.$4,
                ),
              ),
              const Spacer(),
              _statusPill(theme.$4),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _planLabel(state.planCode),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: theme.$5,
                ),
              ),
              const Spacer(),
              if (state.grandfatheredPrice != null &&
                  state.grandfatheredPrice! > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₱${state.grandfatheredPrice!.toStringAsFixed(0)}/mo locked',
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _statusLine(state),
            style: TextStyle(fontSize: 13, height: 1.4, color: theme.$6),
          ),
          if (state.offline) ...[
            const SizedBox(height: 8),
            Text(
              'Offline — showing your saved plan.',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.$6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(Color fg) {
    final (label, _) = _badge(state.effectiveStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }

  (String, Color) _badge(String status) => switch (status) {
        'trialing' => ('TRIAL', AppColors.info),
        'active' => ('ACTIVE', AppColors.success),
        'past_due' => ('PAST DUE', AppColors.warning),
        'lapsed' => ('PAUSED', AppColors.warning),
        _ => ('FREE', AppColors.textSecondary),
      };

  // Returns (bgTop, bgBottom, icon, accent, title, body) for a status.
  (Color, Color, IconData, Color, Color, Color) _theme(String status) {
    switch (status) {
      case 'trialing':
      case 'active':
        return (
          AppColors.brandSoft,
          const Color(0xFFF3F7FF),
          Icons.workspace_premium_rounded,
          AppColors.brand,
          AppColors.textPrimary,
          AppColors.textSecondary,
        );
      case 'past_due':
      case 'lapsed':
        return (
          AppColors.warningSoft,
          const Color(0xFFFFF9EE),
          Icons.pause_circle_outline_rounded,
          AppColors.warning,
          AppColors.textPrimary,
          AppColors.textSecondary,
        );
      default:
        return (
          AppColors.surface,
          AppColors.background,
          Icons.smartphone_rounded,
          AppColors.textSecondary,
          AppColors.textPrimary,
          AppColors.textSecondary,
        );
    }
  }

  String _planLabel(String code) => switch (code) {
        'starter' => 'Starter',
        'growth' => 'Growth',
        'business' => 'Business',
        'enterprise' => 'Enterprise',
        _ => 'Free',
      };

  String _statusLine(BillingState s) {
    final d = s.daysRemaining;
    return switch (s.effectiveStatus) {
      'trialing' => d != null
          ? 'Cloud backup is on us — $d ${_dayWord(d)} left in your trial.'
          : 'You\'re on a free trial with cloud backup.',
      'active' => 'Your data is backed up to the cloud automatically.',
      'past_due' => d != null
          ? 'Payment pending — cloud stays on for $d more ${_dayWord(d)}. '
              'Your POS keeps working.'
          : 'Payment pending — your POS keeps working.',
      'lapsed' =>
        'Cloud is paused. Your data is safe on this device; reactivate anytime.',
      _ => 'Everything runs on this device. Upgrade for cloud backup, more '
          'devices, branches and a team.',
    };
  }

  String _dayWord(int n) => n == 1 ? 'day' : 'days';
}
