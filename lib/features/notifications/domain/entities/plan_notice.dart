import 'package:pos/features/notifications/domain/entities/notification_item.dart';

const kPlanNoticeIdPrefix = 'local:plan:';
const kPlanNoticeRefType = 'plan_notice';

/// Standing plan conditions rendered as synthetic notification rows.
enum PlanNoticeKind {
  trialing,
  pastDue,
  unverified,
  lapsed,
  resourceOverCap,
  deviceCap,
}

extension PlanNoticeKindX on PlanNoticeKind {
  String get id => '$kPlanNoticeIdPrefix$name';

  String get title => switch (this) {
    PlanNoticeKind.trialing => 'Free trial ending',
    PlanNoticeKind.pastDue => 'Payment pending',
    PlanNoticeKind.unverified => 'Subscription needs checking',
    PlanNoticeKind.lapsed => 'Cloud backup paused',
    PlanNoticeKind.resourceOverCap => 'Plan limit exceeded',
    PlanNoticeKind.deviceCap => 'This device isn\'t backed up',
  };

  NotificationSeverity get severity => switch (this) {
    PlanNoticeKind.trialing => NotificationSeverity.low,
    PlanNoticeKind.pastDue ||
    PlanNoticeKind.unverified ||
    PlanNoticeKind.lapsed ||
    PlanNoticeKind.resourceOverCap ||
    PlanNoticeKind.deviceCap => NotificationSeverity.medium,
  };
}

const trialNoticeWindowDays = 7;

PlanNoticeKind? subscriptionNoticeKindForStatus(String status, int? days) {
  switch (status) {
    case 'trialing':
      return (days != null && days <= trialNoticeWindowDays)
          ? PlanNoticeKind.trialing
          : null;
    case 'past_due':
      return PlanNoticeKind.pastDue;
    case 'unverified':
      return PlanNoticeKind.unverified;
    case 'lapsed':
      return PlanNoticeKind.lapsed;
    default:
      return null;
  }
}

PlanNoticeKind? planNoticeKindOf(NotificationItem item) {
  if (item.referenceType != kPlanNoticeRefType) return null;
  for (final kind in PlanNoticeKind.values) {
    if (kind.name == item.referenceId) return kind;
  }
  return null;
}

String subscriptionNoticeBody(PlanNoticeKind kind, int? daysRemaining) {
  final d = daysRemaining;
  switch (kind) {
    case PlanNoticeKind.trialing:
      return d == null
          ? 'Your free trial is ending. Pick a plan to keep cloud backup on.'
          : '$d ${_dayWord(d)} left in your free trial. Pick a plan to keep '
                'cloud backup on.';
    case PlanNoticeKind.pastDue:
      return d == null
          ? 'We\'re retrying your payment. Your POS keeps working.'
          : 'Cloud stays on for $d more ${_dayWord(d)} while we retry your '
                'payment. Your POS keeps working.';
    case PlanNoticeKind.unverified:
      return d == null
          ? 'We haven\'t been able to check your subscription. Connect to '
                'the internet to keep your plan.'
          : 'We haven\'t been able to check your subscription. Connect '
                'within $d ${_dayWord(d)} to keep your plan — nothing is '
                'blocked in the meantime.';
    case PlanNoticeKind.lapsed:
      return 'Your data is safe on this device — upgrade to turn cloud '
          'backup back on.';
    case PlanNoticeKind.resourceOverCap || PlanNoticeKind.deviceCap:
      throw ArgumentError.value(kind, 'kind', 'is not a subscription notice');
  }
}

String _dayWord(int n) => n == 1 ? 'day' : 'days';
