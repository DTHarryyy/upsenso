import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionsRemoteDs {
  final SupabaseClient client;
  TransactionsRemoteDs(this.client);

  /// Upsert a completed transaction to the existing Supabase `transactions` table.
  /// Only Supabase-compatible fields are sent; local-only fields are omitted.
  Future<void> createTransaction({
    required String id,
    required String cashierId,
    String? branchId,
    required double totalAmount,
    required double taxAmount,
    required DateTime createdAt,
  }) async {
    await client.from('transactions').upsert({
      'id': id,
      'branch_id': branchId,
      'cashier_id': cashierId,
      'shift_id': null,
      'total_amount': totalAmount,
      'discount_amount': 0.0,
      'tax_amount': taxAmount,
      'status': 'completed',
      'transaction_hash': null,
      'created_at': createdAt.toIso8601String(),
    });
    // No items upsert — no remote transaction_items table exists
  }
}
