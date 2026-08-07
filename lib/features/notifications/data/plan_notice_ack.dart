import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/features/notifications/domain/entities/plan_notice.dart';

/// Per-device acknowledgement state for synthetic plan notices.
class PlanNoticeAck {
  const PlanNoticeAck(this._prefs);

  final SharedPreferences _prefs;

  String _key(PlanNoticeKind kind, String businessId) =>
      'plan_notice_ack:${kind.name}:$businessId';
  String _oldBillingKey(PlanNoticeKind kind, String businessId) =>
      'billing_notice_ack:${kind.name}:$businessId';
  String _legacyCloudKey(String businessId) => 'cloud_paused_ack:$businessId';

  bool isAcknowledged(PlanNoticeKind kind, String businessId) {
    final current = _prefs.getBool(_key(kind, businessId));
    if (current != null) return current;

    final oldBilling = _prefs.getBool(_oldBillingKey(kind, businessId));
    if (oldBilling != null) return oldBilling;
    if (kind == PlanNoticeKind.lapsed) {
      return _prefs.getBool(_legacyCloudKey(businessId)) ?? false;
    }
    return false;
  }

  Future<void> acknowledge(PlanNoticeKind kind, String businessId) =>
      _prefs.setBool(_key(kind, businessId), true);

  Future<void> reset(PlanNoticeKind kind, String businessId) async {
    await _prefs.remove(_key(kind, businessId));
    await _prefs.remove(_oldBillingKey(kind, businessId));
    if (kind == PlanNoticeKind.lapsed) {
      await _prefs.remove(_legacyCloudKey(businessId));
    }
  }
}
