import 'package:supabase_flutter/supabase_flutter.dart';

/// Mirrors [TransactionsRemoteDs]'s shape — refunds are append-only header +
/// lines pushed/pulled the same way transactions + transaction_items are.
///
/// Pushes use a plain INSERT (not upsert) and tolerate a 23505 unique
/// violation as "already synced from a previous attempt" — same pattern as
/// [AuditLogRemoteDs.upsertLogs]. Refund rows are never legitimately
/// updated after creation, so the server only needs to grant INSERT/SELECT;
/// an upsert's `ON CONFLICT DO UPDATE` would require an UPDATE grant this
/// table should never have.
class RefundsRemoteDs {
  final SupabaseClient client;
  RefundsRemoteDs(this.client);

  Future<void> upsertRefund(Map<String, dynamic> refund) async {
    try {
      await client.from('refunds').insert(refund);
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      rethrow;
    }
  }

  Future<void> upsertRefundItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    try {
      await client.from('refund_items').insert(items);
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      rethrow;
    }
  }

  // ── Refund approval (Phase 1 server foundation: 20260627000013) ─────────────

  /// Reads the business's refund-approval settings. `null` = not configured,
  /// which the server treats as "approval off". Read online before deciding
  /// whether an over-threshold refund needs a manager authorization.
  Future<({bool requireApproval, double threshold})?> fetchRefundSettings(
    String businessId,
  ) async {
    final row = await client
        .from('refund_settings')
        .select('require_approval, approval_threshold')
        .eq('business_id', businessId)
        .maybeSingle();
    if (row == null) return null;
    return (
      requireApproval: row['require_approval'] as bool? ?? false,
      threshold: (row['approval_threshold'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Verifies a manager PIN server-side and issues a single-use, transaction-
  /// and amount-scoped authorization for an over-threshold refund. The refund's
  /// INSERT trigger consumes it on sync. Throws `INVALID_PIN` / `LOCKED` on
  /// failure — the PIN is never checked client-side.
  Future<String> authorizeRefund({
    required String pin,
    required String transactionId,
    required double amount,
  }) async {
    final result = await client.rpc(
      'authorize_refund',
      params: {
        'p_pin': pin,
        'p_transaction_id': transactionId,
        'p_amount': amount,
      },
    );
    return result as String;
  }

  /// Sets/updates a manager PIN — the caller's own, or another employee's when
  /// [employeeId] is given (owner/admin only, enforced server-side). The PIN is
  /// bcrypt-hashed in the database and never stored or compared on the client.
  Future<void> setManagerPin({required String pin, String? employeeId}) async {
    await client.rpc('set_manager_pin', params: {
      'p_pin': pin,
      'p_employee_id': ?employeeId,
    });
  }

  /// Refunds for a business, ordered by (created_at, id) ascending for the
  /// incremental keyset pull. Refunds are append-only — `created_at` is the
  /// right cursor column, same as the stock-ledger pull, since rows are never
  /// updated after insert. Pass the last pulled (afterTs, afterId) to fetch
  /// only newer rows; omit for a full pull.
  Future<List<Map<String, dynamic>>> getRefundsByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) async {
    var filter = client.from('refunds').select().eq('business_id', businessId);
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

  /// Lines for a set of refund ids, chunked to keep request URLs within
  /// limits. Used by the incremental refund pull to fetch each page's items.
  Future<List<Map<String, dynamic>>> getItemsByRefundIds(
    List<String> refundIds,
  ) async {
    final out = <Map<String, dynamic>>[];
    const chunkSize = 100;
    for (var i = 0; i < refundIds.length; i += chunkSize) {
      final end = (i + chunkSize < refundIds.length)
          ? i + chunkSize
          : refundIds.length;
      final res = await client
          .from('refund_items')
          .select()
          .inFilter('refund_id', refundIds.sublist(i, end));
      out.addAll(List<Map<String, dynamic>>.from(res as List));
    }
    return out;
  }
}
