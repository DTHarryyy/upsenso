import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sends a low-stock crossing to Supabase's server-side FCM publisher.
/// Failures are non-fatal so inventory commits remain durable offline.
class LowStockPushPublisher {
  LowStockPushPublisher(this._supabase);

  final SupabaseClient _supabase;

  Future<void> publish({
    required String businessId,
    required String branchId,
    required String variantId,
    required String productName,
    required double quantity,
    required double threshold,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) return;
    try {
      await _supabase.functions
          .invoke(
            'send-low-stock-fcm',
            headers: {'Authorization': 'Bearer $token'},
            body: {
              'businessId': businessId,
              'branchId': branchId,
              'variantId': variantId,
              'productName': productName,
              'quantity': quantity,
              'threshold': threshold,
            },
          )
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('[FCM] Low-stock publish failed: $error\n$stackTrace');
    }
  }
}
