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
      'created_at': createdAt.toIso8601String(),
    });
  }

  Future<void> upsertTransactionItems(
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) return;
    await client.from('transaction_items').upsert(items);
  }

  Future<List<Map<String, dynamic>>> getTransactionsByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('transactions')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
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
}
