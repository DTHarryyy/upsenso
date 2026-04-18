enum ExpenseStatus { approved, pending, rejected, draft }

class ExpenseItem {
  final String id;
  final String businessId;
  final String? branchId;
  final String? branchName;
  final String category;
  final String vendor;
  final double amount;
  final ExpenseStatus status;
  final String submittedById;
  final String submittedByName;
  final String? approvedById;
  final String? approvedByName;
  final String? note;
  final DateTime expenseDate;
  final DateTime createdAt;

  const ExpenseItem({
    required this.id,
    required this.businessId,
    this.branchId,
    this.branchName,
    required this.category,
    required this.vendor,
    required this.amount,
    required this.status,
    required this.submittedById,
    required this.submittedByName,
    this.approvedById,
    this.approvedByName,
    this.note,
    required this.expenseDate,
    required this.createdAt,
  });

  ExpenseItem copyWith({
    ExpenseStatus? status,
    String? approvedById,
    String? approvedByName,
  }) {
    return ExpenseItem(
      id: id,
      businessId: businessId,
      branchId: branchId,
      branchName: branchName,
      category: category,
      vendor: vendor,
      amount: amount,
      status: status ?? this.status,
      submittedById: submittedById,
      submittedByName: submittedByName,
      approvedById: approvedById ?? this.approvedById,
      approvedByName: approvedByName ?? this.approvedByName,
      note: note,
      expenseDate: expenseDate,
      createdAt: createdAt,
    );
  }
}
