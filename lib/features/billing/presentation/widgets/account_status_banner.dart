import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/core/routes/app_routes.dart';

/// A calm, always-honest account-status strip (§4.6). Never a lockout, never
/// sale-blocking — it states the plan situation and offers one tap to billing.
/// Renders nothing on a healthy active/free plan with no action needed.
///
/// Reads EntitlementService directly and repaints on entitlementRevision, so it
/// can sit in the app shell without a cubit.
class AccountStatusBanner extends StatelessWidget {
  const AccountStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final entitlement = sl<EntitlementService>();
    return ValueListenableBuilder<int>(
      valueListenable: entitlement.entitlementRevision,
      builder: (context, _, _) {
        final info = _resolve(entitlement);
        if (info == null) return const SizedBox.shrink();
        return Material(
          color: info.bg,
          child: InkWell(
            onTap: () => context.push(AppRoutes.billing),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(info.icon, size: 18, color: info.fg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      info.message,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: info.fg,
                      ),
                    ),
                  ),
                  Text(
                    info.cta,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: info.fg,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: info.fg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _BannerInfo? _resolve(EntitlementService e) {
    final days = e.daysRemaining;
    switch (e.effectiveStatus) {
      case 'trialing':
        // Calm, not a countdown alarm (§4.7).
        return _BannerInfo(
          message: days != null
              ? 'Cloud backup is on us — $days ${_dayWord(days)} left in your trial.'
              : 'Cloud backup is on us during your trial.',
          cta: 'See plans',
          icon: Icons.cloud_done_outlined,
          fg: AppColors.info,
          bg: AppColors.infoSoft,
        );
      case 'past_due':
        return _BannerInfo(
          message: days != null
              ? 'Payment didn\'t go through — cloud stays on for $days more '
                  '${_dayWord(days)}. Your POS keeps working.'
              : 'Payment didn\'t go through — your POS keeps working.',
          cta: 'Fix payment',
          icon: Icons.schedule_rounded,
          fg: AppColors.warning,
          bg: AppColors.warningSoft,
        );
      case 'unverified':
        // We can't reach the server, so we don't actually know they lapsed —
        // most of these have renewed and simply have no signal. Ask, don't
        // accuse, and keep the plan running until the window closes.
        final left = e.verificationDaysLeft;
        return _BannerInfo(
          message: left != null
              ? 'Connect to the internet to keep ${planLabelOf(e.planCode)} — '
                    '$left ${_dayWord(left)} left to check.'
              : 'Connect to the internet so we can check your subscription.',
          cta: 'Details',
          icon: Icons.cloud_sync_outlined,
          fg: AppColors.warning,
          bg: AppColors.warningSoft,
        );
      case 'lapsed':
        return _BannerInfo(
          message:
              'Your data is safe on this device — cloud backup is paused.',
          cta: 'Reactivate',
          icon: Icons.cloud_off_outlined,
          fg: AppColors.warning,
          bg: AppColors.warningSoft,
        );
      default:
        // free / active: nothing to nag about.
        return null;
    }
  }

  String _dayWord(int n) => n == 1 ? 'day' : 'days';
}

class _BannerInfo {
  final String message;
  final String cta;
  final IconData icon;
  final Color fg;
  final Color bg;

  const _BannerInfo({
    required this.message,
    required this.cta,
    required this.icon,
    required this.fg,
    required this.bg,
  });
}
