import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/database/app_database.dart';

/// Supabase access for the normalized `devices` directory. Small volume (one
/// row per install), so a full tenant pull keeps every device's label
/// converged for the owner's verify UI.
class DevicesRemoteDs {
  final SupabaseClient _client;

  DevicesRemoteDs(this._client);

  Future<void> upsertDevice(DeviceRow r) async {
    await _client.from('devices').upsert({
      'device_uid': r.deviceUid,
      'business_id': r.businessId,
      'label': r.label,
      'platform': r.platform,
      'first_seen_at': r.firstSeenAt.toUtc().toIso8601String(),
      'last_seen_at': r.lastSeenAt.toUtc().toIso8601String(),
    }, onConflict: 'device_uid');
  }

  Future<List<Map<String, dynamic>>> getByBusiness(String businessId) async {
    final res = await _client
        .from('devices')
        .select()
        .eq('business_id', businessId)
        .limit(500);
    return List<Map<String, dynamic>>.from(res as List);
  }
}
