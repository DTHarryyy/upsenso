import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/billing/domain/billing_models.dart';

/// One plan tier in the picker — a centered price header, a full-width CTA, and
/// a checklist of what's included. The recommended tier gets a filled brand-dark
/// "Most Popular" treatment; the user's own tier is marked in-card with a badge
/// and a locked button. The highest tier leads its list with "Everything in
/// {previous}" so the ladder reads at a glance.
class PlanCard extends StatelessWidget {
  final PlanOption plan;

  /// Tier immediately below [plan] in the sorted catalog — names the
  /// "Everything in {previous}" lead bullet on the top tier.
  final PlanOption? previousTier;

  /// The user's current tier — decides upgrade vs. switch CTA wording.
  final PlanOption? currentPlan;

  final bool annual;
  final bool isCurrent;

  /// Marks the tier we steer toward — filled brand-dark card + "Most Popular"
  /// badge. Suppressed when [isCurrent] (no need to sell a plan you're on).
  final bool isRecommended;

  /// Top tier: lead the checklist with "Everything in {previous}" + only the
  /// capabilities this tier adds.
  final bool leadWithEverything;

  final bool busy;
  final bool canManage;

  /// Locked legacy price, shown on the current card only (§4.9 grandfathering).
  final double? grandfatheredPrice;

  final VoidCallback onSelect;

  const PlanCard({
    super.key,
    required this.plan,
    required this.annual,
    required this.isCurrent,
    required this.isRecommended,
    required this.busy,
    required this.canManage,
    required this.onSelect,
    this.previousTier,
    this.currentPlan,
    this.leadWithEverything = false,
    this.grandfatheredPrice,
  });

  /// Filled dark treatment applies only when we're actively selling this tier.
  bool get _popular => isRecommended && !isCurrent;

  @override
  Widget build(BuildContext context) {
    final onDark = _popular;
    final card = Container(
      decoration: BoxDecoration(
        color: onDark ? AppColors.brandDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? AppColors.brand
              : onDark
                  ? AppColors.brandDark
                  : AppColors.borderSoft,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: onDark
            ? [
                BoxShadow(
                  color: AppColors.brandDark.withValues(alpha: 0.28),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: Column(
        children: [
          Text(
            plan.name,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w600,
              color: onDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _price(onDark),
          if (isCurrent && (grandfatheredPrice ?? 0) > 0) ...[
            const SizedBox(height: 8),
            _grandfatherChip(),
          ],
          const SizedBox(height: 10),
          Text(
            _tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.3,
              color: onDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          _cta(onDark),
          const SizedBox(height: 24),
          ..._labels().map((l) => _featureRow(l, onDark)),
        ],
      ),
    );

    // The badge straddles the top edge; the 16px top gutter keeps every card's
    // body top-aligned whether or not it carries a badge.
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(padding: const EdgeInsets.only(top: 16), child: card),
        if (_popular)
          _badge('Most Popular', bg: AppColors.surface, fg: AppColors.brandDark)
        else if (isCurrent)
          _badge('Current plan', bg: AppColors.brand, fg: Colors.white),
      ],
    );
  }

  // ── Price ───────────────────────────────────────────────────────────────────
  Widget _price(bool onDark) {
    final free = plan.priceMonthly == 0;
    final price = annual ? plan.priceAnnual : plan.priceMonthly;
    final suffix = free ? '/forever' : (annual ? '/year' : '/month');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          free ? '₱0' : '₱${_fmt(price)}',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            height: 1,
            color: onDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 5, left: 3),
          child: Text(
            suffix,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: onDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String get _tagline => switch (plan.code) {
        'free' => 'Perfect for a single store',
        'starter' => 'For growing businesses',
        'growth' => 'For multi-branch operations',
        'business' => 'For large operations',
        _ => 'Run your business smarter',
      };

  Widget _grandfatherChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Price locked at ₱${grandfatheredPrice!.toStringAsFixed(0)}/mo',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }

  // ── CTA ─────────────────────────────────────────────────────────────────────
  Widget _cta(bool onDark) {
    if (isCurrent) {
      return _ghostButton(
        label: 'Current plan',
        icon: Icons.check_rounded,
        fg: AppColors.brand,
        side: AppColors.brand,
      );
    }
    // Free has no checkout — you reach it by letting a paid plan lapse.
    if (plan.priceMonthly == 0) {
      return _ghostButton(
        label: 'Free forever',
        fg: AppColors.textMuted,
        side: AppColors.borderSoft,
      );
    }

    final upgrade =
        currentPlan == null || plan.priceMonthly > currentPlan!.priceMonthly;
    final enabled = !busy && canManage;
    final label = !canManage
        ? 'Owner only'
        : upgrade
            ? 'Upgrade to ${plan.name}'
            : 'Switch to ${plan.name}';

    if (onDark) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onSelect : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandSoft,
            foregroundColor: AppColors.brandDark,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.25),
            disabledForegroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: Text(enabled ? '$label  →' : label),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onSelect : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          side: const BorderSide(color: AppColors.brand),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _ghostButton({
    required String label,
    required Color fg,
    required Color side,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: fg,
          side: BorderSide(color: side),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
            Text(label),
          ],
        ),
      ),
    );
  }

  // ── Feature checklist ───────────────────────────────────────────────────────
  Widget _featureRow(String label, bool onDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 18,
            color: onDark ? Colors.white : AppColors.brand,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: onDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _labels() {
    if (leadWithEverything && previousTier != null) {
      return [
        'Everything in ${previousTier!.name}',
        ..._caps(plan, previousTier).where((r) => r.changed).map((r) => r.label),
      ];
    }
    return _caps(plan, null).map((r) => r.label).toList();
  }

  /// Capability rows for [p]. When [prev] is given, `changed` marks the rows
  /// that differ from the tier below (used to build the delta list).
  List<({String label, bool changed})> _caps(PlanOption p, PlanOption? prev) {
    final rows = <({String label, bool changed})>[];
    void add(String label, bool changed) => rows.add((label: label, changed: changed));

    add(
      p.cloudEnabled ? 'Cloud backup & sync' : 'Works fully offline',
      prev == null || p.cloudEnabled != prev.cloudEnabled,
    );
    add(_count(p.maxDevices, 'device', 'devices'),
        prev == null || p.maxDevices != prev.maxDevices);
    add(_count(p.maxBranches, 'branch', 'branches'),
        prev == null || p.maxBranches != prev.maxBranches);
    add(_count(p.maxSeats, 'team member', 'team members'),
        prev == null || p.maxSeats != prev.maxSeats);

    final crm = _crmRank(p.featureFlags['crm']);
    if (crm > 0) {
      add(crm == 2 ? 'Full CRM & customer insights' : 'Customer directory (CRM)',
          prev == null || crm != _crmRank(prev.featureFlags['crm']));
    }
    if (p.featureFlags['procurement'] == true) {
      add('Procurement & suppliers',
          prev == null || prev.featureFlags['procurement'] != true);
    }
    final rep = _reportsRank(p.featureFlags['reports']);
    add(rep == 2 ? 'Advanced reports & export' : 'Sales & inventory reports',
        prev == null || rep != _reportsRank(prev.featureFlags['reports']));
    if (p.featureFlags['cloud_audit'] == true) {
      add('Cloud audit trail',
          prev == null || prev.featureFlags['cloud_audit'] != true);
    }
    return rows;
  }

  // ── Badge ───────────────────────────────────────────────────────────────────
  Widget _badge(String label, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x14101828), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  static int _crmRank(Object? v) => v == 'full' ? 2 : (v == 'basic' ? 1 : 0);

  static int _reportsRank(Object? v) => v == 'full' ? 2 : 1;

  static String _count(int? n, String one, String many) =>
      n == null ? 'Unlimited $many' : '$n ${n == 1 ? one : many}';

  static String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
