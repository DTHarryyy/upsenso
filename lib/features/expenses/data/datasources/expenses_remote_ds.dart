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
      'expense_date': expenseDate.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
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
      'updated_at': updatedAt.toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteExpense(String id) async {
    await client.from('expenses').delete().eq('id', id);
  }

  /// Incremental/paged pull, keyset ordered by (updated_at, id). Omit the cursor
  /// + limit for a full first-run pull. Note: expenses have no soft-delete
  /// column, so a hard-deleted expense doesn't propagate to other devices under
  /// either full or delta pull (unchanged behavior); a future soft-delete
  /// migration would close that gap.
  Future<List<Map<String, dynamic>>> getExpensesByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) async {
    var filter = client.from('expenses').select().eq('business_id', businessId);
    if (afterTs != null) {
      final ts = afterTs.toUtc().toIso8601String();
      filter = afterId != null
          ? filter.or('updated_at.gt.$ts,and(updated_at.eq.$ts,id.gt.$afterId)')
          : filter.gt('updated_at', ts);
    }
    final ordered =
        filter.order('updated_at', ascending: true).order('id', ascending: true);
    final res = limit != null ? await ordered.limit(limit) : await ordered;
    return List<Map<String, dynamic>>.from(res);
  }
}
