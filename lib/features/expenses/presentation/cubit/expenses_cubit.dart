import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/expenses/domain/repositories/i_expenses_repository.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';
import 'package:pos/features/expenses/presentation/cubit/expenses_state.dart';

class ExpensesCubit extends Cubit<ExpensesState> {
  final IExpensesRepository _repository;

  StreamSubscription<List<ExpenseItem>>? _watcher;
  String? _businessId;
  String? _branchId;
  String? _userId;
  String? _userName;

  // Local filter state
  String _searchQuery = '';
  ExpenseStatus? _statusFilter;
  String? _categoryFilter;
  DateTimeRange? _dateRange;
  ExpensesViewMode _viewMode = ExpensesViewMode.table;

  // Guards against a double-tap on an approve/reject button firing the same
  // mutation twice before the list stream re-emits and hides the button.
  final Set<String> _inFlightApprovalActions = {};

  ExpensesCubit(this._repository) : super(const ExpensesInitial());

  bool get canApprove =>
      sl<PermissionService>().can(PermissionKeys.expensesApprove);

  bool get _shouldAutoApprove => canApprove;

  Future<void> startWatching({
    required String businessId,
    String? branchId,
    String? roleName,
    String? userId,
    String? userName,
  }) async {
    _businessId = businessId;
    _branchId = branchId;
    _userId = userId;
    _userName = userName;

    await _watcher?.cancel();
    emit(const ExpensesLoading());

    _watcher = _repository
        .watchExpenses(businessId)
        .listen(
          (items) {
            if (!isClosed) _onDataChanged(items);
          },
          onError: (e) {
            if (!isClosed) emit(ExpensesError(AppErrorMapper.message(e)));
          },
        );
  }

  void _onDataChanged(List<ExpenseItem> items) {
    final filtered = _filter(items);
    final current = state;
    if (current is ExpensesLoaded) {
      emit(
        current.copyWith(
          allItems: items,
          displayItems: filtered,
          canApprove: canApprove,
        ),
      );
    } else {
      emit(
        ExpensesLoaded(
          allItems: items,
          displayItems: filtered,
          searchQuery: _searchQuery,
          statusFilter: _statusFilter,
          categoryFilter: _categoryFilter,
          dateRange: _dateRange,
          viewMode: _viewMode,
          canApprove: canApprove,
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setStatusFilter(ExpenseStatus? status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    _applyFilters();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    _applyFilters();
  }

  void setViewMode(ExpensesViewMode mode) {
    _viewMode = mode;
    final current = state;
    if (current is ExpensesLoaded) emit(current.copyWith(viewMode: mode));
  }

  void _applyFilters() {
    final current = state;
    if (current is! ExpensesLoaded) return;
    emit(
      current.copyWith(
        displayItems: _filter(current.allItems),
        searchQuery: _searchQuery,
        statusFilter: _statusFilter,
        categoryFilter: _categoryFilter,
        dateRange: _dateRange,
      ),
    );
  }

  List<ExpenseItem> _filter(List<ExpenseItem> items) {
    var result = items;

    if (_branchId != null) {
      result = result.where((e) => e.branchId == _branchId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (e) =>
                e.vendor.toLowerCase().contains(q) ||
                e.category.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_statusFilter != null) {
      result = result.where((e) => e.status == _statusFilter).toList();
    }

    if (_categoryFilter != null) {
      result = result.where((e) => e.category == _categoryFilter).toList();
    }

    if (_dateRange != null) {
      final start = _dateRange!.start;
      final end = _dateRange!.end.add(const Duration(days: 1));
      result = result
          .where(
            (e) =>
                e.expenseDate.isAfter(
                  start.subtract(const Duration(seconds: 1)),
                ) &&
                e.expenseDate.isBefore(end),
          )
          .toList();
    }

    return result;
  }

  Future<void> addExpense({
    required String category,
    required String vendor,
    required double amount,
    required String? branchId,
    required String? branchName,
    required String? note,
    required DateTime expenseDate,
    ExpenseStatus? overrideStatus,
  }) async {
    final businessId = _businessId;
    if (businessId == null || _userId == null) return;

    final autoApprove = overrideStatus == null
        ? _shouldAutoApprove
        : overrideStatus == ExpenseStatus.approved;

    await _repository.addExpense(
      businessId: businessId,
      branchId: branchId,
      branchName: branchName,
      category: category,
      vendor: vendor,
      amount: amount,
      submittedById: _userId!,
      submittedByName: _userName ?? 'Unknown',
      note: note,
      expenseDate: expenseDate,
      autoApprove: autoApprove,
      overrideStatus: overrideStatus,
    );

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.expenseCreated,
      entityType: 'expense',
      entityName: '$vendor — $category',
      description: 'Expense created: $vendor — $category (\$$amount)',
      metadata: {
        'vendor': vendor,
        'category': category,
        'amount': amount,
        'auto_approved': autoApprove,
      },
      businessId: businessId,
      branchId: branchId ?? '',
      userId: _userId,
    );
  }

  Future<void> approveExpense(String id) async {
    if (_userId == null) return;
    if (!_inFlightApprovalActions.add(id)) return; // already approving/rejecting
    try {
      await _repository.approveExpense(
        id: id,
        approvedById: _userId!,
        approvedByName: _userName ?? 'Unknown',
      );
      final approvedItem = state is ExpensesLoaded
          ? (state as ExpensesLoaded).allItems
                .where((e) => e.id == id)
                .firstOrNull
          : null;
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.expenseApproved,
        entityType: 'expense',
        entityName: approvedItem != null
            ? '${approvedItem.vendor} — ${approvedItem.category}'
            : null,
        description: approvedItem != null
            ? 'Expense approved: ${approvedItem.vendor} — ${approvedItem.category}'
            : 'Expense approved',
        businessId: _businessId ?? '',
        branchId: _branchId ?? '',
        userId: _userId,
      );
    } finally {
      _inFlightApprovalActions.remove(id);
    }
  }

  Future<void> rejectExpense(String id) async {
    if (!_inFlightApprovalActions.add(id)) return; // already approving/rejecting
    try {
      await _repository.rejectExpense(id);
      final rejectedItem = state is ExpensesLoaded
          ? (state as ExpensesLoaded).allItems
                .where((e) => e.id == id)
                .firstOrNull
          : null;
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.expenseRejected,
        entityType: 'expense',
        entityName: rejectedItem != null
            ? '${rejectedItem.vendor} — ${rejectedItem.category}'
            : null,
        description: rejectedItem != null
            ? 'Expense rejected: ${rejectedItem.vendor} — ${rejectedItem.category}'
            : 'Expense rejected',
        businessId: _businessId ?? '',
        branchId: _branchId ?? '',
        userId: _userId,
      );
    } finally {
      _inFlightApprovalActions.remove(id);
    }
  }

  @override
  Future<void> close() async {
    await _watcher?.cancel();
    return super.close();
  }
}
