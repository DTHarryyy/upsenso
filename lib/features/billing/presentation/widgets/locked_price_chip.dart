import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/billing/presentation/billing_formats.dart';

/// "Your locked price · ₱149/mo" — shown to a tenant grandfathered below
/// today's list price (§4.9). The caller decides whether a lock is real; this
/// only renders it.
class LockedPriceChip extends StatelessWidget {
  final double price;

  const LockedPriceChip({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Your locked price · ₱${formatPlanPrice(price)}/mo',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }
}
