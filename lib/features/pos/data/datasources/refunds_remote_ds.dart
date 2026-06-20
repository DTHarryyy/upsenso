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
