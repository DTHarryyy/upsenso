import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/features/billing/domain/billing_models.dart';

/// A verify-play-purchase call that did not grant. [status] is the HTTP status
/// from the edge function, which is what tells a caller whether retrying can
/// ever help: 5xx / 0 (network) are transient, 4xx are the server's final word.
class PlayVerifyException implements Exception {
  final int status;
  final String message;

  /// Machine-readable fault class from the edge function (`play_config`,
  /// `play_transient`), when it sent one. Free text is for humans; retry policy
  /// keys off this.
  final String? code;

  /// Which server stage failed (`google_get_sub`, `grant`, …). Diagnostics only.
  final String? stage;

  const PlayVerifyException(this.status, this.message, {this.code, this.stage});

  /// The server answered definitively — re-sending the same token will get the
  /// same answer, so a retry loop is pointless.
  bool get isPermanent => status >= 400 && status < 500;

  /// Our own misconfiguration (bad Play credentials, missing API access). It
  /// arrives as a 5xx, but no client retry can ever clear it — so it must not
  /// be presented to the user as "retrying automatically".
  bool get isConfigFault => code == 'play_config';

  /// The token was replaced by a newer purchase — an upgrade's old subscription.
  /// Nothing is wrong and nothing was lost, so it must never reach the user:
  /// Play keeps returning the superseded token for a while after a plan change,
  /// and reporting that as a failed purchase is how a successful upgrade ended
  /// up showing "we couldn't confirm your purchase".
  bool get isSuperseded => code == 'play_superseded';

  @override
  String toString() =>
      'PlayVerifyException($status${stage == null ? '' : '/$stage'}): $message';
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
      throw _exceptionOf(data, res.status);
    } on FunctionException catch (e) {
      // supabase_flutter raises this for any non-2xx; the body still carries
      // our own {"error", "code", "stage"}, which is the only useful diagnostic.
      throw _exceptionOf(e.details, e.status);
    }
  }

  /// Ask the server to self-check its Play configuration. No purchase involved,
  /// so this is safe to run any number of times. Throws [PlayVerifyException] if
  /// the call itself couldn't complete — a check that merely *failed* comes back
  /// as a normal result with `ok: false`.
  Future<List<BillingProbeCheck>> probePlayConfig() async {
    try {
      final res = await _client.functions
          .invoke('verify-play-purchase', body: {'probe': true});
      return _checksOf(res.data, res.status);
    } on FunctionException catch (e) {
      throw _exceptionOf(e.details, e.status);
    }
  }

  static List<BillingProbeCheck> _checksOf(dynamic data, int status) {
    final raw = data is Map ? data['checks'] : null;
    if (raw is! List) throw _exceptionOf(data, status);
    return raw.whereType<Map>().map((c) {
      return BillingProbeCheck(
        stage: c['stage']?.toString() ?? 'unknown',
        ok: c['ok'] == true,
        detail: c['detail']?.toString() ?? '',
      );
    }).toList();
  }

  static PlayVerifyException _exceptionOf(dynamic data, int status) {
    final map = data is Map ? data : const {};
    final detail = map['detail']?.toString();
    if (detail != null && detail.isNotEmpty) {
      // Server-side stage detail never reaches the user, but it is exactly what
      // makes a production failure diagnosable from a device log.
      debugPrint('[BillingRemoteDs] verify failed ($status): $detail');
    }
    return PlayVerifyException(
      status,
      map['error']?.toString() ?? 'Verification failed ($status)',
      code: map['code']?.toString(),
      stage: map['stage']?.toString(),
    );
  }

  static DateTime? _ts(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
}
