import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/features/billing/domain/billing_models.dart';

/// A verify-play-purchase call that did not grant. [status] is the HTTP status
/// from the edge function, which is what tells a caller whether retrying can
/// ever help: 5xx / 0 (network) are transient, 4xx are the server's final word.
class PlayVerifyException implements Exception {
  final int status;
  final String message;

  const PlayVerifyException(this.status, this.message);

  /// The server answered definitively — re-sending the same token will get the
  /// same answer, so a retry loop is pointless.
  bool get isPermanent => status >= 400 && status < 500;

  @override
  String toString() => 'PlayVerifyException($status): $message';
}

/// Supabase reads for the billing catalog + history, the Play SKU map, and the
/// purchase-verify invoke.
///
/// Catalog tables (plans/plan_limits/play_product_map) are world-readable to
/// signed-in users; subscription/payment rows are tenant-scoped by RLS. A Play
/// purchase is verified server-side (verify-play-purchase) against Google — the
/// client's purchase is never trusted as proof of entitlement.
class BillingRemoteDs {
  final SupabaseClient _client;

  BillingRemoteDs(this._client);

  Future<List<PlanOption>> fetchPlans() async {
    final plans = await _client
        .from('plans')
        .select('code, version, name, price_monthly, is_active')
        .eq('is_active', true);
    final limits = await _client
        .from('plan_limits')
        .select('plan_code, plan_version, cloud_enabled, max_branches, '
            'max_seats, max_devices, feature_flags');

    final limitByKey = {
      for (final l in (limits as List))
        '${l['plan_code']}:${l['plan_version']}': l as Map<String, dynamic>
    };

    return (plans as List).map((p) {
      final row = p as Map<String, dynamic>;
      final l = limitByKey['${row['code']}:${row['version']}'] ?? const {};
      return PlanOption(
        code: row['code'] as String,
        version: (row['version'] as num).toInt(),
        name: row['name'] as String,
        priceMonthly: (row['price_monthly'] as num).toDouble(),
        isActive: row['is_active'] == true,
        cloudEnabled: l['cloud_enabled'] == true,
        maxBranches: (l['max_branches'] as num?)?.toInt(),
        maxSeats: (l['max_seats'] as num?)?.toInt(),
        maxDevices: (l['max_devices'] as num?)?.toInt(),
        featureFlags: (l['feature_flags'] is Map)
            ? Map<String, dynamic>.from(l['feature_flags'] as Map)
            : const {},
      );
    }).toList()
      ..sort((a, b) => a.priceMonthly.compareTo(b.priceMonthly));
  }

  Future<List<BillingPayment>> fetchPayments() async {
    final rows = await _client
        .from('billing_payments')
        .select('id, kind, amount, currency, status, is_test, created_at, '
            'plan_code, addon_code')
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((r) => BillingPayment(
              id: r['id'] as String,
              kind: r['kind'] as String,
              amount: (r['amount'] as num).toDouble(),
              currency: (r['currency'] as String?) ?? 'PHP',
              status: r['status'] as String,
              isTest: r['is_test'] == true,
              createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
              planCode: r['plan_code'] as String?,
              addonCode: r['addon_code'] as String?,
            ))
        .toList();
  }

  Future<List<RegisteredDevice>> fetchDevices() async {
    final rows = await _client
        .from('registered_devices')
        .select('device_uid, label, platform, registered_at, last_seen_at, revoked_at')
        .order('registered_at', ascending: false);
    return (rows as List)
        .map((r) => RegisteredDevice(
              deviceUid: r['device_uid'] as String,
              label: (r['label'] as String?) ?? 'Device',
              platform: (r['platform'] as String?) ?? 'unknown',
              registeredAt: _ts(r['registered_at']),
              lastSeenAt: _ts(r['last_seen_at']),
              revokedAt: _ts(r['revoked_at']),
            ))
        .toList();
  }

  /// The Play SKU → plan map (active rows only). The client queries Play for
  /// live prices using these product ids — they're never hardcoded in the app.
  Future<List<PlayProductMapping>> fetchPlayProducts() async {
    final rows = await _client
        .from('play_product_map')
        .select('product_id, base_plan_id, plan_code, plan_version, billing_period')
        .eq('is_active', true);
    return (rows as List)
        .map((r) => PlayProductMapping(
              productId: r['product_id'] as String,
              basePlanId: (r['base_plan_id'] as String?) ?? '',
              planCode: r['plan_code'] as String,
              planVersion: (r['plan_version'] as num).toInt(),
              billingPeriod: r['billing_period'] as String,
            ))
        .toList();
  }

  /// Hands a Play purchase to the verify-play-purchase edge function — the sole
  /// grantor of Premium. Throws [PlayVerifyException] on any non-grant so the
  /// caller can tell a retryable fault from a permanent one; success means
  /// Supabase has recorded the entitlement.
  Future<void> verifyPlayPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    try {
      final res = await _client.functions.invoke('verify-play-purchase', body: {
        'product_id': productId,
        'purchase_token': purchaseToken,
      });
      final data = res.data;
      if (res.status == 200 && data is Map && data['ok'] == true) return;
      throw PlayVerifyException(res.status, _messageOf(data, res.status));
    } on FunctionException catch (e) {
      // supabase_flutter raises this for any non-2xx; the body still carries
      // our own {"error": …}, which is the only useful diagnostic.
      throw PlayVerifyException(e.status, _messageOf(e.details, e.status));
    }
  }

  static String _messageOf(dynamic data, int status) {
    if (data is Map && data['error'] != null) return data['error'].toString();
    return 'Verification failed ($status)';
  }

  static DateTime? _ts(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
}
