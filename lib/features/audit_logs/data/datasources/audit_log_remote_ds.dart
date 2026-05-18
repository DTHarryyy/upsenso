import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogRemoteDs {
  final SupabaseClient _client;

  AuditLogRemoteDs(this._client);

  Future<void> upsertLogs(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('audit_logs').upsert(rows);
  }

  Future<List<Map<String, dynamic>>> getByBusiness(
    String businessId, {
    int limit = 500,
  }) async {
    final response = await _client
        .from('audit_logs')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }
}
