import 'package:supabase_flutter/supabase_flutter.dart';

class ExpensesRemoteDs {
  final SupabaseClient client;
  ExpensesRemoteDs(this.client);

  Future<void> upsertExpense({
    required String id,
    required String businessId,
    String? branchId,
    String? branchName,
    required String category,
    required String vendor,
    required double amount,
    required String status,
    required String submittedById,
    required String submittedByName,
    String? approvedById,
    String? approvedByName,
    String? note,
    required DateTime expenseDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    await client.from('expenses').upsert({
      'id': id,
      'business_id': businessId,
      'branch_id': branchId,
      'branch_name': branchName,
      'category': category,
      'vendor': vendor,
      'amount': amount,
      'status': status,
      'submitted_by_id': submittedById,
      'submitted_by_name': submittedByName,
      'approved_by_id': approvedById,
      'approved_by_name': approvedByName,
      'note': note,
      'expense_date': expenseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    });
  }

  Future<void> updateExpenseStatus({
    required String id,
    required String status,
    String? approvedById,
    String? approvedByName,
    required DateTime updatedAt,
  }) async {
    await client.from('expenses').update({
      'status': status,
      'approved_by_id': approvedById,
      'approved_by_name': approvedByName,
      'updated_at': updatedAt.toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteExpense(String id) async {
    await client.from('expenses').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getExpensesByBusiness(
      String businessId) async {
    final response = await client
        .from('expenses')
        .select()
        .eq('business_id', businessId)
        .order('expense_date', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }
}
