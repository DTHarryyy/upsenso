import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote reads for the tenant's subscription entitlement.
///
/// One RPC round trip (`get_my_entitlement`) returns the subscription row,
/// server-computed effective status, effective limits (snapshot + add-ons)
/// and usage counts. Business identity is derived server-side from auth.uid();
/// nothing tenant-identifying is ever passed as a parameter.
class EntitlementRemoteDs {
  final SupabaseClient _client;

  EntitlementRemoteDs(this._client);

  Future<Map<String, dynamic>> fetchMyEntitlement() async {
    final dynamic result = await _client.rpc('get_my_entitlement');
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    throw StateError('get_my_entitlement returned ${result.runtimeType}');
  }
}
