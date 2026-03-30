import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionsRemoteDs {
  final SupabaseClient client;
  TransactionsRemoteDs(this.client);

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
  }
}
