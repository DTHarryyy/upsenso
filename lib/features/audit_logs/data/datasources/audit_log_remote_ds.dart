import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogRemoteDs {
  final SupabaseClient _client;

  AuditLogRemoteDs(this._client);

  Future<void> upsertLogs(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    try {
      await _client.from('audit_logs').insert(rows);
    } on PostgrestException catch (e) {
      // 23505 = unique_violation: row already synced from a previous attempt.
      if (e.code == '23505') return;
      rethrow;
    }
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
