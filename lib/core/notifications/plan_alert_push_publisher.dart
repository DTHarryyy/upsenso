import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Requests an authoritative server evaluation of plan-limit push conditions.
/// The server derives tenant identity, limits, and counts; client values only
/// identify which device-registration episode should be evaluated.
class PlanAlertPushPublisher {
  PlanAlertPushPublisher(this._supabase);

  final SupabaseClient _supabase;

  Future<void> evaluateEntitlement() =>
      _invoke(const {'trigger': 'entitlement_changed'});

  Future<void> evaluateDevice(String deviceUid) =>
      _invoke({'trigger': 'device_registration', 'deviceUid': deviceUid});

  Future<void> _invoke(Map<String, Object> body) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) return;
    try {
      await _supabase.functions
          .invoke(
            'send-plan-limit-fcm',
            headers: {'Authorization': 'Bearer $token'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('[FCM] Plan-limit evaluation failed: $error\n$stackTrace');
    }
  }
}
