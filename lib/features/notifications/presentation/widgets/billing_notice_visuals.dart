import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/notifications/domain/entities/billing_notice.dart';

/// Per-kind icon, palette and CTA for the synthetic billing notices.
///
/// Kept out of the domain enum so `billing_notice.dart` stays free of
/// `material.dart`, and out of NotificationTile so the tile gains no second
/// switch on top of the one it already has for notification types.
extension BillingNoticeVisuals on BillingNoticeKind {
  IconData get icon => switch (this) {
    BillingNoticeKind.trialing => Icons.schedule_rounded,
    BillingNoticeKind.pastDue => Icons.credit_card_rounded,
    BillingNoticeKind.unverified => Icons.cloud_sync_outlined,
    BillingNoticeKind.lapsed => Icons.cloud_off_outlined,
  };

  Color get color => switch (this) {
    BillingNoticeKind.trialing => AppColors.info,
    BillingNoticeKind.pastDue => AppColors.warning,
    BillingNoticeKind.unverified => AppColors.warning,
    BillingNoticeKind.lapsed => AppColors.warning,
  };

  Color get softColor => switch (this) {
    BillingNoticeKind.trialing => AppColors.infoSoft,
    BillingNoticeKind.pastDue => AppColors.warningSoft,
    BillingNoticeKind.unverified => AppColors.warningSoft,
    BillingNoticeKind.lapsed => AppColors.warningSoft,
  };

  /// All four land on the same Billing route — the wording differs because
  /// "Upgrade" is wrong advice for a card that merely needs re-authorising,
  /// and wronger still for a plan we simply haven't been able to check.
  String get ctaLabel => switch (this) {
    BillingNoticeKind.trialing => 'See plans',
    BillingNoticeKind.pastDue => 'Fix payment',
    BillingNoticeKind.unverified => 'Check now',
    BillingNoticeKind.lapsed => 'Upgrade',
  };
}
