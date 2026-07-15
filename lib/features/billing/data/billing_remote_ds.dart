import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/features/billing/domain/billing_models.dart';

/// Supabase reads for the billing catalog + history, and the checkout invoke.
///
/// Catalog tables (plans/plan_limits/plan_addons) are world-readable to signed-
/// in users; subscription/payment rows are tenant-scoped by RLS; the checkout
/// amount is computed server-side in the edge function (never trusted here).
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

  Future<List<PlanAddon>> fetchAddons() async {
    final rows = await _client
        .from('plan_addons')
        .select('code, name, price_monthly, unit_qty')
        .eq('is_active', true);
    return (rows as List)
        .map((r) => PlanAddon(
              code: r['code'] as String,
              name: r['name'] as String,
              priceMonthly: (r['price_monthly'] as num).toDouble(),
              unitQty: (r['unit_qty'] as num).toInt(),
            ))
        .toList();
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

  /// Invokes the create-checkout edge function; returns the hosted checkout URL.
  /// Amount is derived server-side from the plan/addon — the client only names
  /// what it wants to buy.
  Future<String> createCheckout({
    required String kind, // plan | addon
    String? planCode,
    int? planVersion,
    String? billingPeriod, // monthly | annual
    String? addonCode,
    int? addonQty,
  }) async {
    final res = await _client.functions.invoke('create-checkout', body: {
      'kind': kind,
      'plan_code': ?planCode,
      'plan_version': ?planVersion,
      'billing_period': ?billingPeriod,
      'addon_code': ?addonCode,
      'addon_qty': ?addonQty,
    });
    final data = res.data;
    if (data is Map && data['checkout_url'] is String) {
      return data['checkout_url'] as String;
    }
    throw StateError('create-checkout returned no checkout_url');
  }

  static DateTime? _ts(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
}
