import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';

enum ExpensesViewMode { table, cards }

abstract class ExpensesState extends Equatable {
  const ExpensesState();
  @override
  List<Object?> get props => [];
}

class ExpensesInitial extends ExpensesState {
  const ExpensesInitial();
}

class ExpensesLoading extends ExpensesState {
  const ExpensesLoading();
}

class ExpensesLoaded extends ExpensesState {
  final List<ExpenseItem> allItems;
  final List<ExpenseItem> displayItems;
  final String searchQuery;
  final ExpenseStatus? statusFilter;
  final String? categoryFilter;
  final DateTimeRange? dateRange;
  final ExpensesViewMode viewMode;
  final bool canApprove;

  const ExpensesLoaded({
    required this.allItems,
    required this.displayItems,
    this.searchQuery = '',
    this.statusFilter,
    this.categoryFilter,
    this.dateRange,
    this.viewMode = ExpensesViewMode.table,
    this.canApprove = false,
  });

  double get totalApproved => allItems
      .where((e) => e.status == ExpenseStatus.approved)
      .fold(0.0, (s, e) => s + e.amount);

  double get totalPending => allItems
      .where((e) => e.status == ExpenseStatus.pending)
      .fold(0.0, (s, e) => s + e.amount);

  int get pendingCount =>
      allItems.where((e) => e.status == ExpenseStatus.pending).length;

  ExpensesLoaded copyWith({
    List<ExpenseItem>? allItems,
    List<ExpenseItem>? displayItems,
    String? searchQuery,
    Object? statusFilter = _sentinel,
    Object? categoryFilter = _sentinel,
    Object? dateRange = _sentinel,
    ExpensesViewMode? viewMode,
    bool? canApprove,
  }) {
    return ExpensesLoaded(
      allItems: allItems ?? this.allItems,
      displayItems: displayItems ?? this.displayItems,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter == _sentinel
          ? this.statusFilter
          : statusFilter as ExpenseStatus?,
      categoryFilter: categoryFilter == _sentinel
          ? this.categoryFilter
          : categoryFilter as String?,
      dateRange:
          dateRange == _sentinel ? this.dateRange : dateRange as DateTimeRange?,
      viewMode: viewMode ?? this.viewMode,
      canApprove: canApprove ?? this.canApprove,
    );
  }

  @override
  List<Object?> get props => [
        allItems,
        displayItems,
        searchQuery,
        statusFilter,
        categoryFilter,
        dateRange,
        viewMode,
        canApprove,
      ];
}

class ExpensesError extends ExpensesState {
  final String message;
  const ExpensesError(this.message);
  @override
  List<Object?> get props => [message];
}

const _sentinel = Object();
