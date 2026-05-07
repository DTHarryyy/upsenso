import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/expenses_dao.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';
import 'package:pos/features/expenses/domain/repositories/i_expenses_repository.dart';

class ExpensesRepository implements IExpensesRepository {
  final ExpensesDao _expensesDao;
  static const _uuid = Uuid();

  ExpensesRepository({required ExpensesDao expensesDao})
    : _expensesDao = expensesDao;

  Stream<void> watchChanges(String businessId) {
    return _expensesDao.watchByBusinessId(businessId).map((_) {});
  }

  @override
  Future<List<ExpenseItem>> loadExpenses(String businessId) async {
    final rows = await _expensesDao.getByBusinessId(businessId);
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<ExpenseItem>> watchExpenses(String businessId) {
    return _expensesDao
        .watchByBusinessId(businessId)
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
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
  }) async {
    final id = _uuid.v4();
    final status = overrideStatus != null
        ? overrideStatus.name
        : (autoApprove ? 'approved' : 'pending');

    await _expensesDao.insertExpense(
      ExpensesTableCompanion.insert(
        id: id,
        businessId: businessId,
        branchId: Value(branchId),
        branchName: Value(branchName),
        category: category,
        vendor: vendor,
        amount: amount,
        status: Value(status),
        submittedById: submittedById,
        submittedByName: submittedByName,
        approvedById: autoApprove ? Value(submittedById) : const Value(null),
        approvedByName: autoApprove
            ? Value(submittedByName)
            : const Value(null),
        note: Value(note),
        expenseDate: expenseDate,
      ),
    );
  }

  @override
  Future<void> approveExpense({
    required String id,
    required String approvedById,
    required String approvedByName,
  }) async {
    await _expensesDao.updateExpense(
      id,
      ExpensesTableCompanion(
        status: const Value('approved'),
        approvedById: Value(approvedById),
        approvedByName: Value(approvedByName),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(1),
      ),
    );
  }

  @override
  Future<void> rejectExpense(String id) async {
    await _expensesDao.updateExpense(
      id,
      ExpensesTableCompanion(
        status: const Value('rejected'),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(1),
      ),
    );
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _expensesDao.deleteExpense(id);
  }

  static ExpenseItem _toEntity(ExpenseRow row) {
    return ExpenseItem(
      id: row.id,
      businessId: row.businessId,
      branchId: row.branchId,
      branchName: row.branchName,
      category: row.category,
      vendor: row.vendor,
      amount: row.amount,
      status: _parseStatus(row.status),
      submittedById: row.submittedById,
      submittedByName: row.submittedByName,
      approvedById: row.approvedById,
      approvedByName: row.approvedByName,
      note: row.note,
      expenseDate: row.expenseDate,
      createdAt: row.createdAt,
    );
  }

  static ExpenseStatus _parseStatus(String s) {
    return switch (s) {
      'approved' => ExpenseStatus.approved,
      'rejected' => ExpenseStatus.rejected,
      'draft' => ExpenseStatus.draft,
      _ => ExpenseStatus.pending,
    };
  }
}
