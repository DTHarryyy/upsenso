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
import 'package:pos/core/widgets/app_status_badge.dart';
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

class _BillingViewState extends State<_BillingView> {
  bool _annual = false;
  bool _busy = false;

  bool get _canManage => sl<PermissionService>().can(PermissionKeys.billingManage);

  Future<void> _launch(Future<String> Function() start) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final url = await start();
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack('Could not open the checkout page.');
    } catch (e) {
      if (mounted) _snack('Checkout failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Billing & Subscription'),
        backgroundColor: AppColors.surface,
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
                _currentPlanCard(state),
                const SizedBox(height: 16),
                if (_showMeters(state)) ...[
                  _usageCard(state),
                  const SizedBox(height: 16),
                ],
                _planPickerCard(context, state),
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

  // ── Current plan ───────────────────────────────────────────────────────────
  Widget _currentPlanCard(BillingState s) {
    final badge = _statusBadge(s.effectiveStatus);
    return AppSectionCard(
      title: 'Your plan',
      icon: Icons.workspace_premium_outlined,
      trailing: AppStatusBadge(label: badge.$1, color: badge.$2),
      children: [
        Row(
          children: [
            Text(
              _planLabel(s.planCode),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (s.grandfatheredPrice != null && s.grandfatheredPrice! > 0)
              Text('₱${s.grandfatheredPrice!.toStringAsFixed(0)}/mo locked',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _statusLine(s),
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (s.offline) ...[
          const SizedBox(height: 8),
          const Text('Offline — showing your saved plan. Connect to manage it.',
              style: TextStyle(fontSize: 12, color: AppColors.warning)),
        ],
      ],
    );
  }

  // ── Usage meters ────────────────────────────────────────────────────────────
  Widget _usageCard(BillingState s) {
    return AppSectionCard(
      title: 'Usage',
      icon: Icons.speed_outlined,
      children: [
        UsageMeter(label: 'Branches', used: s.branchUsage, max: s.maxBranches),
        const SizedBox(height: 12),
        UsageMeter(label: 'Seats', used: s.seatUsage, max: s.maxSeats),
        const SizedBox(height: 12),
        UsageMeter(label: 'Devices', used: s.deviceUsage, max: s.maxDevices),
      ],
    );
  }

  // ── Plan picker ─────────────────────────────────────────────────────────────
  Widget _planPickerCard(BuildContext context, BillingState s) {
    return AppSectionCard(
      title: 'Plans',
      icon: Icons.grid_view_rounded,
      trailing: _periodToggle(),
      children: [
        if (s.plans.isEmpty)
          const Text('Connect to see available plans.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
        else
          ...s.plans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PlanCard(
                  plan: p,
                  annual: _annual,
                  isCurrent: p.code == s.planCode &&
                      s.effectiveStatus != 'lapsed' &&
                      s.effectiveStatus != 'free',
                  busy: _busy,
                  canManage: _canManage,
                  onSelect: () => _launch(() => context
                      .read<BillingCubit>()
                      .startPlanCheckout(
                          p.code, p.version, _annual ? 'annual' : 'monthly')),
                ),
              )),
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
                TextButton(
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
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_invoiceLabel(p)}  ·  ${_date(p.createdAt)}'
                    '${p.isTest ? '  (test)' : ''}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                Text('₱${p.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                AppStatusBadge(
                    label: p.status,
                    color: p.status == 'paid'
                        ? AppColors.success
                        : p.status == 'failed'
                            ? AppColors.error
                            : AppColors.warning),
              ],
            ),
          ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  (String, Color) _statusBadge(String status) => switch (status) {
        'trialing' => ('Trial', AppColors.info),
        'active' => ('Active', AppColors.success),
        'past_due' => ('Past due', AppColors.warning),
        'lapsed' => ('Lapsed', AppColors.warning),
        _ => ('Free', AppColors.textSecondary),
      };

  String _statusLine(BillingState s) {
    final d = s.daysRemaining;
    return switch (s.effectiveStatus) {
      'trialing' => d != null
          ? 'Cloud backup on us — $d day(s) left in your trial.'
          : 'You\'re on a free trial with cloud backup.',
      'active' => 'Your data is backed up to the cloud automatically.',
      'past_due' => d != null
          ? 'Payment pending — cloud stays on for $d more day(s).'
          : 'Payment pending — your POS keeps working.',
      'lapsed' =>
        'Cloud is paused. Your data is safe on this device; reactivate anytime.',
      _ => 'Everything runs on this device. Upgrade for cloud backup + more.',
    };
  }

  String _planLabel(String code) => switch (code) {
        'starter' => 'Starter',
        'growth' => 'Growth',
        'business' => 'Business',
        'enterprise' => 'Enterprise',
        _ => 'Free',
      };

  String _invoiceLabel(BillingPayment p) => p.kind == 'addon'
      ? 'Add-on: ${p.addonCode ?? ''}'
      : 'Plan: ${_planLabel(p.planCode ?? 'free')}';

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
