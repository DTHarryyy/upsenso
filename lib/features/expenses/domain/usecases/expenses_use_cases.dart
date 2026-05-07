import 'package:pos/features/expenses/domain/expense_item.dart';
import 'package:pos/features/expenses/domain/repositories/i_expenses_repository.dart';

class WatchExpensesUseCase {
  final IExpensesRepository _repository;
  const WatchExpensesUseCase(this._repository);

  Stream<List<ExpenseItem>> call(String businessId) =>
      _repository.watchExpenses(businessId);
}

class AddExpenseUseCase {
  final IExpensesRepository _repository;
  const AddExpenseUseCase(this._repository);

  Future<void> call({
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
  }) => _repository.addExpense(
    businessId: businessId,
    branchId: branchId,
    branchName: branchName,
    category: category,
    vendor: vendor,
    amount: amount,
    submittedById: submittedById,
    submittedByName: submittedByName,
    note: note,
    expenseDate: expenseDate,
    autoApprove: autoApprove,
    overrideStatus: overrideStatus,
  );
}

class ApproveExpenseUseCase {
  final IExpensesRepository _repository;
  const ApproveExpenseUseCase(this._repository);

  Future<void> call({
    required String id,
    required String approvedById,
    required String approvedByName,
  }) => _repository.approveExpense(
    id: id,
    approvedById: approvedById,
    approvedByName: approvedByName,
  );
}

class RejectExpenseUseCase {
  final IExpensesRepository _repository;
  const RejectExpenseUseCase(this._repository);

  Future<void> call(String id) => _repository.rejectExpense(id);
}
