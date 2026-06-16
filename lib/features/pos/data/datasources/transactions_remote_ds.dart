import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionsRemoteDs {
  final SupabaseClient client;
  TransactionsRemoteDs(this.client);

  Future<void> createTransaction({
    required String id,
    required String cashierId,
    String? businessId,
    String? branchId,
    required double totalAmount,
    required double discountAmount,
    required double taxAmount,
    required DateTime createdAt,
    String paymentMethod = 'cash',
    String? invoiceNumber,
  }) async {
    await client.from('transactions').upsert({
      'id': id,
      'business_id': businessId,
      'branch_id': branchId,
      'cashier_id': cashierId,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'status': 'completed',
      'payment_method': paymentMethod,
      'invoice_number': invoiceNumber,
      'created_at': createdAt.toUtc().toIso8601String(),
    });
  }

  Future<void> upsertTransactionItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    await client.from('transaction_items').upsert(items);
  }

  /// Transactions for a business, ordered by (updated_at, id) ascending so the
  /// incremental pull can page forward with a keyset cursor. Pass the last
  /// pulled (afterTs, afterId) to fetch only changed rows; omit for a full pull.
  Future<List<Map<String, dynamic>>> getTransactionsByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) async {
    var filter =
        client.from('transactions').select().eq('business_id', businessId);
    if (afterTs != null) {
      final ts = afterTs.toUtc().toIso8601String();
      filter = afterId != null
          ? filter
              .or('updated_at.gt.$ts,and(updated_at.eq.$ts,id.gt.$afterId)')
          : filter.gt('updated_at', ts);
    }
    final ordered = filter
        .order('updated_at', ascending: true)
        .order('id', ascending: true);
    final res = limit != null ? await ordered.limit(limit) : await ordered;
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Line items for a set of transaction ids, chunked to keep request URLs
  /// within limits. Used by the incremental transaction pull to fetch each
  /// page's items (items are append-only, written with their transaction).
  Future<List<Map<String, dynamic>>> getItemsByTransactionIds(
    List<String> transactionIds,
  ) async {
    final out = <Map<String, dynamic>>[];
    const chunkSize = 100;
    for (var i = 0; i < transactionIds.length; i += chunkSize) {
      final end = (i + chunkSize < transactionIds.length)
          ? i + chunkSize
          : transactionIds.length;
      final res = await client
          .from('transaction_items')
          .select()
          .inFilter('transaction_id', transactionIds.sublist(i, end));
      out.addAll(List<Map<String, dynamic>>.from(res as List));
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> getItemsByTransaction(
    String transactionId,
  ) async {
    final response = await client
        .from('transaction_items')
        .select()
        .eq('transaction_id', transactionId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Fetch all transaction items for a business by joining through transactions.
  /// Used during pull sync so all line-item data is available locally.
  Future<List<Map<String, dynamic>>> getItemsByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('transaction_items')
        .select('*, transactions!inner(business_id)')
        .eq('transactions.business_id', businessId);
    return List<Map<String, dynamic>>.from(response as List);
  }
}
