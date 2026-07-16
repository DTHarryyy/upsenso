import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/billing/domain/billing_models.dart';

/// One selectable plan in the picker — name, price with ₱/day framing, the
/// annual "2 months free" line, a capability checklist, and the CTA. A
/// recommended plan gets a highlighted border + ribbon; the current plan is
/// visually locked.
class PlanCard extends StatelessWidget {
  final PlanOption plan;
  final bool annual;
  final bool isCurrent;
  final bool isRecommended;
  final bool busy;
  final bool canManage;
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
  });

  @override
  Widget build(BuildContext context) {
    final free = plan.priceMonthly == 0;
    final price = annual ? plan.priceAnnual : plan.priceMonthly;
    final period = annual ? '/yr' : '/mo';
    final accent = isCurrent
        ? AppColors.brand
        : isRecommended
            ? AppColors.brand
            : AppColors.borderSoft;

    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.brandSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent,
          width: (isCurrent || isRecommended) ? 1.5 : 1,
        ),
        boxShadow: isRecommended && !isCurrent
            ? const [
                BoxShadow(
                  color: Color(0x14557FF4),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended && !isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: const BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          free ? 'Free' : '₱${_fmt(price)}$period',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!free)
                          Text(
                            '~₱${plan.perDay.toStringAsFixed(2)}/day',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (!free && annual)
                          const Text(
                            '2 months free',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._features().map(_featureRow),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: isCurrent
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text('Current plan'),
                        )
                      : free
                          ? const SizedBox.shrink()
                          : FilledButton(
                              onPressed: (busy || !canManage) ? null : onSelect,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brand,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                              ),
                              child: Text(
                                canManage ? 'Choose ${plan.name}' : 'Owner only',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
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

  Widget _featureRow((bool, String) f) {
    final (included, label) = f;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 16,
            color: included ? AppColors.success : AppColors.borderSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: included ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// (included, label) capability rows for the checklist.
  List<(bool, String)> _features() {
    final crm = plan.featureFlags['crm'];
    return [
      (plan.cloudEnabled, plan.cloudEnabled
          ? 'Cloud backup + sync'
          : 'Local only — this device'),
      (true, _deviceLabel()),
      (true, '${plan.maxBranches ?? '∞'} branch${plan.maxBranches == 1 ? '' : 'es'}'),
      (crm == 'basic' || crm == 'full', crm == 'full' ? 'Full CRM' : 'Customer directory'),
      (plan.featureFlags['procurement'] == true, 'Procurement & suppliers'),
      (plan.featureFlags['reports'] == 'full', 'Full reports + export'),
    ];
  }

  String _deviceLabel() {
    final d = plan.maxDevices;
    if (d == null) return 'Unlimited devices';
    return '$d device${d == 1 ? '' : 's'}';
  }

  static String _fmt(double v) {
    // Thousands separator for the annual figures (₱4,990).
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
