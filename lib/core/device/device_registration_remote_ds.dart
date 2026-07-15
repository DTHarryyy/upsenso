import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper over the device-registration RPCs (M7.1 §6.3).
/// Business identity is derived server-side from auth.uid(); never passed.
class DeviceRegistrationRemoteDs {
  final SupabaseClient _client;

  DeviceRegistrationRemoteDs(this._client);

  /// Returns 'registered' | 'cap_reached'. Online-only by construction.
  Future<String> register({
    required String deviceUid,
    required String label,
    required String platform,
  }) async {
    final dynamic result = await _client.rpc('register_device', params: {
      'p_device_uid': deviceUid,
      'p_label': label,
      'p_platform': platform,
    });
    return result?.toString() ?? 'cap_reached';
  }

  Future<void> revoke(String deviceUid) async {
    await _client.rpc('revoke_device', params: {'p_device_uid': deviceUid});
  }

  Future<void> touch(String deviceUid) async {
    await _client.rpc('touch_device', params: {'p_device_uid': deviceUid});
  }
}
