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

  /// Audit logs for a business, ordered by (created_at, id) ascending for the
  /// incremental keyset pull — mirrors [RefundsRemoteDs.getRefundsByBusiness].
  /// Audit rows are append-only, so `created_at` is a safe, never-changing
  /// cursor column. Pass the last pulled (afterTs, afterId) to fetch only
  /// newer rows; omit for a full pull.
  Future<List<Map<String, dynamic>>> getAuditLogsByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) async {
    var filter = _client
        .from('audit_logs')
        .select()
        .eq('business_id', businessId);
    if (afterTs != null) {
      final ts = afterTs.toUtc().toIso8601String();
      filter = afterId != null
          ? filter.or('created_at.gt.$ts,and(created_at.eq.$ts,id.gt.$afterId)')
          : filter.gt('created_at', ts);
    }
    final ordered = filter
        .order('created_at', ascending: true)
        .order('id', ascending: true);
    final res = limit != null ? await ordered.limit(limit) : await ordered;
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// On-demand fetch for history older than the local retention window — the
  /// server keeps every row forever, so this is how a user reaches entries
  /// that [AuditLogsDao.pruneOlderThan] has already cleared off the device.
  /// Ordered newest-first within the range, to match the local list's order.
  /// [before] excludes a row already seen (paging further back); omit for the
  /// first page of a given range.
  Future<List<Map<String, dynamic>>> getAuditLogsInRange(
    String businessId, {
    required DateTime from,
    DateTime? before,
    int limit = 200,
  }) async {
    var filter = _client
        .from('audit_logs')
        .select()
        .eq('business_id', businessId)
        .gte('created_at', from.toUtc().toIso8601String());
    if (before != null) {
      filter = filter.lt('created_at', before.toUtc().toIso8601String());
    }
    final res = await filter
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res as List);
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
    List<String>? excludeActionTypes,
    int limit = 1,
  }) async {
    var filter = _client
        .from('audit_logs')
        .select()
        .eq('business_id', businessId)
        .eq('user_id', userId);
    if (actionType != null) {
      filter = filter.eq('action_type', actionType);
    }
    if (excludeActionTypes != null && excludeActionTypes.isNotEmpty) {
      filter = filter.not(
        'action_type',
        'in',
        '(${excludeActionTypes.join(',')})',
      );
    }
    final response = await filter
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }
}
