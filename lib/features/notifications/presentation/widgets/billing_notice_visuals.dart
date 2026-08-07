import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/notifications/domain/entities/plan_notice.dart';

/// Per-kind icon, palette and CTA for synthetic plan notices.
///
/// Kept out of the domain enum so `plan_notice.dart` stays free of
/// `material.dart`, and out of NotificationTile so the tile gains no second
/// switch on top of the one it already has for notification types.
extension PlanNoticeVisuals on PlanNoticeKind {
  IconData get icon => switch (this) {
    PlanNoticeKind.trialing => Icons.schedule_rounded,
    PlanNoticeKind.pastDue => Icons.credit_card_rounded,
    PlanNoticeKind.unverified => Icons.cloud_sync_outlined,
    PlanNoticeKind.lapsed => Icons.cloud_off_outlined,
    PlanNoticeKind.resourceOverCap => Icons.lock_outline_rounded,
    PlanNoticeKind.deviceCap => Icons.phonelink_lock_outlined,
  };

  Color get color => switch (this) {
    PlanNoticeKind.trialing => AppColors.info,
    PlanNoticeKind.pastDue ||
    PlanNoticeKind.unverified ||
    PlanNoticeKind.lapsed ||
    PlanNoticeKind.resourceOverCap ||
    PlanNoticeKind.deviceCap => AppColors.warning,
  };

  Color get softColor => switch (this) {
    PlanNoticeKind.trialing => AppColors.infoSoft,
    PlanNoticeKind.pastDue ||
    PlanNoticeKind.unverified ||
    PlanNoticeKind.lapsed ||
    PlanNoticeKind.resourceOverCap ||
    PlanNoticeKind.deviceCap => AppColors.warningSoft,
  };

  /// All four land on the same Billing route — the wording differs because
  /// "Upgrade" is wrong advice for a card that merely needs re-authorising,
  /// and wronger still for a plan we simply haven't been able to check.
  String get ctaLabel => switch (this) {
    PlanNoticeKind.trialing => 'See plans',
    PlanNoticeKind.pastDue => 'Fix payment',
    PlanNoticeKind.unverified => 'Check now',
    PlanNoticeKind.lapsed => 'Upgrade',
    PlanNoticeKind.resourceOverCap => 'Upgrade',
    PlanNoticeKind.deviceCap => 'Manage devices',
  };
}
