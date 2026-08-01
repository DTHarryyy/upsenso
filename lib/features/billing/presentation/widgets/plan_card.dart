import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/domain/plan_benefits.dart';
import 'package:pos/features/billing/presentation/billing_formats.dart';
import 'package:pos/features/billing/presentation/widgets/locked_price_chip.dart';

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

  /// Legacy price this tenant is locked into, below today's list price
  /// (§4.9 grandfathering). The CALLER decides whether a lock is real — this
  /// renders the chip whenever it's non-null. Passing the entitlement's raw
  /// value here is what put a lapsed Growth tenant's "₱499" on the Free card.
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
          if (grandfatheredPrice != null) ...[
            const SizedBox(height: 8),
            LockedPriceChip(price: grandfatheredPrice!),
          ] else if (_perDay != null) ...[
            const SizedBox(height: 6),
            Text(
              _perDay!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: onDark ? Colors.white60 : AppColors.textMuted,
              ),
            ),
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
          ..._rows().map((r) => PlanBenefitRow(benefit: r, onDark: onDark)),
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
    // Scale down rather than clip: three cards side by side leave ~200px each,
    // which an annual price ("₱4,990 /year") does not fit at 38px.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            free ? '₱0' : '₱${formatPlanPrice(price)}',
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
      ),
    );
  }

  /// A monthly figure is easy to flinch at; the same number as a daily one is
  /// what a shop owner can compare against a day's takings.
  String? get _perDay {
    if (plan.priceMonthly <= 0) return null;
    final perDay = annual ? plan.priceAnnual / 365.0 : plan.perDay;
    return 'About ₱${perDay.toStringAsFixed(0)} a day';
  }

  String get _tagline => switch (plan.code) {
        'free' => 'Perfect for a single store',
        'starter' => 'For growing businesses',
        'growth' => 'For multi-branch operations',
        'business' => 'For large operations',
        _ => 'Run your business smarter',
      };

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
  List<PlanBenefit> _rows() {
    if (leadWithEverything && previousTier != null) {
      final delta =
          planBenefits(plan, previous: previousTier).where((r) => r.changed);
      // Two tiers with identical limits would leave the card selling nothing
      // but its own name — fall back to the full list rather than a bare lead.
      if (delta.isEmpty) return planBenefits(plan);
      return [
        (
          label: 'Everything in ${previousTier!.name}',
          detail: null,
          changed: true,
        ),
        ...delta,
      ];
    }
    return planBenefits(plan);
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
}

/// One checklist line: a tick, the capability, and the plain-language gloss
/// under it. Always a tick — a plan card states what a tier gives you, never
/// what it withholds.
class PlanBenefitRow extends StatelessWidget {
  final PlanBenefit benefit;
  final bool onDark;

  const PlanBenefitRow({
    super.key,
    required this.benefit,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = onDark ? Colors.white : AppColors.brand;
    final labelColor = onDark ? Colors.white : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
                if (benefit.detail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      benefit.detail!,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color:
                            onDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
