import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/features/billing/domain/billing_models.dart';

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
  /// grantor of Premium. Throws with a message on any non-grant so the cubit can
  /// surface it; success means Supabase has recorded the entitlement.
  Future<void> verifyPlayPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    final res = await _client.functions.invoke('verify-play-purchase', body: {
      'product_id': productId,
      'purchase_token': purchaseToken,
    });
    final data = res.data;
    final ok = res.status == 200 && data is Map && data['ok'] == true;
    if (!ok) {
      final msg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Verification failed (${res.status})';
      throw StateError(msg);
    }
  }

  static DateTime? _ts(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
}
