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

  /// A user's activity may have been recorded on a device other than the
  /// one viewing it (e.g. a manager checking an employee's last login), so
  /// this reads straight from Supabase instead of the local audit trail.
  /// RLS already restricts `audit_logs` SELECT to super admins — everyone
  /// else gets an empty result, not an error.
  Future<List<Map<String, dynamic>>> getByUser(
    String businessId,
    String userId, {
    String? actionType,
    int limit = 1,
  }) async {
    final filter = _client
        .from('audit_logs')
        .select()
        .eq('business_id', businessId)
        .eq('user_id', userId);
    final response = await (actionType != null
            ? filter.eq('action_type', actionType)
            : filter)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }
}
