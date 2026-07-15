import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/billing/domain/billing_models.dart';

/// One selectable plan in the picker — name, price with ₱/day framing, the
/// annual "2 months free" line, a short capability summary, and the CTA.
class PlanCard extends StatelessWidget {
  final PlanOption plan;
  final bool annual;
  final bool isCurrent;
  final bool busy;
  final bool canManage;
  final VoidCallback onSelect;

  const PlanCard({
    super.key,
    required this.plan,
    required this.annual,
    required this.isCurrent,
    required this.busy,
    required this.canManage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final free = plan.priceMonthly == 0;
    final price = annual ? plan.priceAnnual : plan.priceMonthly;
    final period = annual ? '/yr' : '/mo';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.brandSoft : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.brand : AppColors.borderSoft,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(_summary(),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    free ? 'Free' : '₱${price.toStringAsFixed(0)}$period',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                  if (!free)
                    Text('~₱${plan.perDay.toStringAsFixed(2)}/day',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  if (!free && annual)
                    const Text('2 months free',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    child: const Text('Current plan'),
                  )
                : free
                    ? const SizedBox.shrink()
                    : FilledButton(
                        onPressed: (busy || !canManage) ? null : onSelect,
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brand),
                        child: Text(canManage ? 'Choose ${plan.name}' : 'Owner only'),
                      ),
          ),
        ],
      ),
    );
  }

  String _summary() {
    final parts = <String>[];
    parts.add(plan.cloudEnabled ? 'Cloud backup' : 'Local only');
    if (plan.maxDevices != null) parts.add('${plan.maxDevices} device(s)');
    final crm = plan.featureFlags['crm'];
    if (crm == 'full') parts.add('Full CRM');
    if (plan.featureFlags['procurement'] == true) parts.add('Procurement');
    return parts.join(' · ');
  }
}
