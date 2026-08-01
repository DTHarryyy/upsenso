import 'package:flutter/foundation.dart';

import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/features/notifications/data/billing_notice_ack.dart';
import 'package:pos/features/notifications/domain/entities/billing_notice.dart';
import 'package:pos/features/notifications/domain/entities/notification_item.dart';

/// The one place that decides whether a billing notice is showing.
///
/// Both the Notifications list and the shell's bell badge need that answer, and
/// they used to derive it separately — two copies of the same rule that could
/// disagree. They now both read this.
///
/// Reads ([visibleKind], [build]) are pure so the badge can call them from
/// `build()`; anything that writes to disk is behind [reArm] or [acknowledge].
class BillingNoticeService {
  final EntitlementService _entitlement;
  final BillingNoticeAck _ack;

  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  /// Stable across the process. A fresh `DateTime.now()` per synthesis would
  /// make the item unequal to its predecessor and rebuild the whole list on
  /// every entitlement tick — and these notices render no timestamp anyway.
  final DateTime _createdAt = DateTime.now();

  BillingNoticeService(this._entitlement, this._ack) {
    _entitlement.entitlementRevision.addListener(_bump);
  }

  /// Bumps on an entitlement change *and* on [acknowledge] — dismissing a
  /// notice fires no realtime event, so this is the badge's only signal.
  ValueListenable<int> get revision => _revision;

  /// The notice that should be visible for [businessId], or null.
  BillingNoticeKind? visibleKind(String businessId) {
    final kind = billingNoticeKindForStatus(
      _entitlement.effectiveStatus,
      _entitlement.daysRemaining,
    );
    if (kind == null) return null;
    return _ack.isAcknowledged(kind, businessId) ? null : kind;
  }

  /// The synthetic list item for [businessId], or null when nothing is due.
  NotificationItem? build(String businessId) {
    final kind = visibleKind(businessId);
    if (kind == null) return null;
    return NotificationItem(
      id: kind.id,
      businessId: businessId,
      type: NotificationType.billing,
      severity: kind.severity,
      title: kind.title,
      body: kind.body(_entitlement.daysRemaining),
      isRead: false,
      referenceType: kBillingNoticeRefType,
      referenceId: kind.name,
      createdAt: _createdAt,
    );
  }

  /// Clears the acks of every kind that isn't currently due, so a later
  /// transition (trial → past due → lapsed) arrives unread instead of
  /// inheriting a dismissal from a state the tenant has since left.
  Future<void> reArm(String businessId) async {
    final active = billingNoticeKindForStatus(
      _entitlement.effectiveStatus,
      _entitlement.daysRemaining,
    );
    for (final kind in BillingNoticeKind.values) {
      if (kind == active) continue;
      if (!_ack.isAcknowledged(kind, businessId)) continue;
      await _ack.reset(kind, businessId);
    }
  }

  Future<void> acknowledge(BillingNoticeKind kind, String businessId) async {
    await _ack.acknowledge(kind, businessId);
    _bump();
  }

  /// Is [id] one of ours, rather than a real notification row?
  static bool isSyntheticId(String id) => id.startsWith(kBillingNoticeIdPrefix);

  void _bump() => _revision.value++;

  /// Process-lifetime singleton — nothing but DI teardown should call this.
  void dispose() {
    _entitlement.entitlementRevision.removeListener(_bump);
    _revision.dispose();
  }
}
