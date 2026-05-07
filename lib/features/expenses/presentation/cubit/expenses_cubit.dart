import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/features/expenses/domain/repositories/i_expenses_repository.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';
import 'package:pos/features/expenses/presentation/cubit/expenses_state.dart';

class ExpensesCubit extends Cubit<ExpensesState> {
  final IExpensesRepository _repository;

  StreamSubscription<List<ExpenseItem>>? _watcher;
  String? _businessId;
  String? _branchId;
  String? _roleName;
  String? _userId;
  String? _userName;

  // Local filter state
  String _searchQuery = '';
  ExpenseStatus? _statusFilter;
  String? _categoryFilter;
  DateTimeRange? _dateRange;
  ExpensesViewMode _viewMode = ExpensesViewMode.table;

  ExpensesCubit(this._repository) : super(const ExpensesInitial());

  bool get canApprove {
    final normalized = _roleName?.trim().toLowerCase() ?? '';
    return normalized == 'owner' ||
        normalized == 'super admin' ||
        normalized.contains('admin');
  }

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
    _roleName = roleName;
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
  }

  Future<void> approveExpense(String id) async {
    if (_userId == null) return;
    await _repository.approveExpense(
      id: id,
      approvedById: _userId!,
      approvedByName: _userName ?? 'Unknown',
    );
  }

  Future<void> rejectExpense(String id) async {
    await _repository.rejectExpense(id);
  }

  @override
  Future<void> close() async {
    await _watcher?.cancel();
    return super.close();
  }
}
