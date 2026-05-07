import 'package:pos/features/expenses/domain/expense_item.dart';

abstract class IExpensesRepository {
  Stream<List<ExpenseItem>> watchExpenses(String businessId);
  Future<List<ExpenseItem>> loadExpenses(String businessId);

  Future<void> addExpense({
    required String businessId,
    required String? branchId,
    required String? branchName,
    required String category,
    required String vendor,
    required double amount,
    required String submittedById,
    required String submittedByName,
    required String? note,
    required DateTime expenseDate,
    required bool autoApprove,
    ExpenseStatus? overrideStatus,
  });

  Future<void> approveExpense({
    required String id,
    required String approvedById,
    required String approvedByName,
  });

  Future<void> rejectExpense(String id);
  Future<void> deleteExpense(String id);
}
