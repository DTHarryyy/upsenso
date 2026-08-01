import 'package:pos/features/notifications/domain/entities/notification_item.dart';

/// Prefix for the synthetic notice ids. Never collides with a real row's UUID.
const kBillingNoticeIdPrefix = 'local:billing:';

/// Marks a [NotificationItem] as one of these locally-synthesized notices, so
/// the tile can vary icon and CTA without keying off `type` alone.
const kBillingNoticeRefType = 'billing_notice';

/// The entitlement states worth telling a merchant about.
///
/// Each of these used to be a banner pinned above the Billing tab bar. They
/// live in Notifications now — merchants look at the bell for alerts, not at a
/// settings page they only open when something is already wrong.
enum BillingNoticeKind { trialing, pastDue, unverified, lapsed }

extension BillingNoticeKindX on BillingNoticeKind {
  String get id => '$kBillingNoticeIdPrefix$name';

  String get title => switch (this) {
    BillingNoticeKind.trialing => 'Free trial ending',
    BillingNoticeKind.pastDue => 'Payment pending',
    BillingNoticeKind.unverified => 'Subscription needs checking',
    BillingNoticeKind.lapsed => 'Cloud backup paused',
  };

  NotificationSeverity get severity => switch (this) {
    BillingNoticeKind.trialing => NotificationSeverity.low,
    BillingNoticeKind.pastDue => NotificationSeverity.medium,
    BillingNoticeKind.unverified => NotificationSeverity.medium,
    BillingNoticeKind.lapsed => NotificationSeverity.medium,
  };

  /// [daysRemaining] is null whenever the entitlement cache has no end date to
  /// count down to — say the number only when we actually know it.
  String body(int? daysRemaining) {
    final d = daysRemaining;
    switch (this) {
      case BillingNoticeKind.trialing:
        return d == null
            ? 'Your free trial is ending. Pick a plan to keep cloud backup on.'
            : '$d ${_dayWord(d)} left in your free trial. Pick a plan to keep '
                  'cloud backup on.';
      case BillingNoticeKind.pastDue:
        return d == null
            ? 'We\'re retrying your payment. Your POS keeps working.'
            : 'Cloud stays on for $d more ${_dayWord(d)} while we retry your '
                  'payment. Your POS keeps working.';
      case BillingNoticeKind.unverified:
        return d == null
            ? 'We haven\'t been able to check your subscription. Connect to '
                  'the internet to keep your plan.'
            : 'We haven\'t been able to check your subscription. Connect '
                  'within $d ${_dayWord(d)} to keep your plan — nothing is '
                  'blocked in the meantime.';
      case BillingNoticeKind.lapsed:
        return 'Your data is safe on this device — upgrade to turn cloud '
            'backup back on.';
    }
  }
}

/// How long before a trial ends we start nagging. A month-long trial must not
/// park a permanent unread badge on the bell from day one — this only fires
/// once it's actually worth acting on.
const _trialNoticeWindowDays = 7;

/// The single notice for an entitlement state, or null when there's nothing to
/// say. [status] comes from `EntitlementService.effectiveStatus`, which returns
/// exactly one value — so at most one notice is ever live.
BillingNoticeKind? billingNoticeKindForStatus(String status, int? days) {
  switch (status) {
    case 'trialing':
      return (days != null && days <= _trialNoticeWindowDays)
          ? BillingNoticeKind.trialing
          : null;
    case 'past_due':
      return BillingNoticeKind.pastDue;
    case 'unverified':
      return BillingNoticeKind.unverified;
    case 'lapsed':
      return BillingNoticeKind.lapsed;
    default:
      return null; // active | free — nothing to report
  }
}

/// The kind behind a rendered [item], or null for every real notification row.
BillingNoticeKind? billingNoticeKindOf(NotificationItem item) {
  if (item.referenceType != kBillingNoticeRefType) return null;
  for (final kind in BillingNoticeKind.values) {
    if (kind.name == item.referenceId) return kind;
  }
  return null;
}

String _dayWord(int n) => n == 1 ? 'day' : 'days';
