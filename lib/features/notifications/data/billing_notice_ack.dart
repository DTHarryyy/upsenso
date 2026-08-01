import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/features/notifications/domain/entities/billing_notice.dart';

/// Tracks which synthetic billing notices the merchant has dismissed.
///
/// These notices have no backing row in `notifications` — they're derived live
/// from EntitlementService, so both the Notifications list and the shell's bell
/// badge need to agree on whether one has been dismissed. Scoped per business
/// and per kind: dismissing "your trial is ending" must not also pre-dismiss
/// the "payment pending" notice that arrives weeks later.
class BillingNoticeAck {
  final SharedPreferences _prefs;

  const BillingNoticeAck(this._prefs);

  String _key(BillingNoticeKind kind, String businessId) =>
      'billing_notice_ack:${kind.name}:$businessId';

  /// The single-purpose key this class replaced. Only ever held the lapsed
  /// ("cloud backup paused") notice.
  String _legacyKey(String businessId) => 'cloud_paused_ack:$businessId';

  bool isAcknowledged(BillingNoticeKind kind, String businessId) {
    final current = _prefs.getBool(_key(kind, businessId));
    if (current != null) return current;
    // Read through to the old key so merchants who already dismissed the
    // cloud-paused notice don't see it resurrect after this upgrade.
    if (kind == BillingNoticeKind.lapsed) {
      return _prefs.getBool(_legacyKey(businessId)) ?? false;
    }
    return false;
  }

  Future<void> acknowledge(BillingNoticeKind kind, String businessId) =>
      _prefs.setBool(_key(kind, businessId), true);

  Future<void> reset(BillingNoticeKind kind, String businessId) async {
    await _prefs.remove(_key(kind, businessId));
    // Clear the legacy key too, or the read-through above would keep the
    // lapsed notice dismissed forever after a reactivation.
    if (kind == BillingNoticeKind.lapsed) {
      await _prefs.remove(_legacyKey(businessId));
    }
  }
}
