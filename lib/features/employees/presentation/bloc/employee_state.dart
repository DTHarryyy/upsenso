import 'package:equatable/equatable.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';

abstract class EmployeeState extends Equatable {
  const EmployeeState();
  @override
  List<Object?> get props => [];
}

class EmployeeInitial extends EmployeeState {
  const EmployeeInitial();
}

class EmployeeLoading extends EmployeeState {
  const EmployeeLoading();
}

class EmployeeLoaded extends EmployeeState {
  final List<Employee> allEmployees;
  final List<Employee> displayEmployees;
  final String searchQuery;

  /// Filter by role name string. Null = all roles.
  final String? roleFilter;

  /// Filter by active status. Null = all.
  final bool? isActiveFilter;

  final String? branchFilter;

  const EmployeeLoaded({
    required this.allEmployees,
    required this.displayEmployees,
    this.searchQuery = '',
    this.roleFilter,
    this.isActiveFilter,
    this.branchFilter,
  });

  @override
  List<Object?> get props => [
        allEmployees,
        displayEmployees,
        searchQuery,
        roleFilter,
        isActiveFilter,
        branchFilter,
      ];

  int get activeCount => allEmployees.where((e) => e.isActive).length;
  int get inactiveCount => allEmployees.where((e) => !e.isActive).length;

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      roleFilter != null ||
      isActiveFilter != null ||
      branchFilter != null;

  EmployeeLoaded copyWith({
    List<Employee>? allEmployees,
    List<Employee>? displayEmployees,
    String? searchQuery,
    Object? roleFilter = _sentinel,
    Object? isActiveFilter = _sentinel,
    Object? branchFilter = _sentinel,
  }) {
    return EmployeeLoaded(
      allEmployees: allEmployees ?? this.allEmployees,
      displayEmployees: displayEmployees ?? this.displayEmployees,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: identical(roleFilter, _sentinel)
          ? this.roleFilter
          : roleFilter as String?,
      isActiveFilter: identical(isActiveFilter, _sentinel)
          ? this.isActiveFilter
          : isActiveFilter as bool?,
      branchFilter: identical(branchFilter, _sentinel)
          ? this.branchFilter
          : branchFilter as String?,
    );
  }

  static const _sentinel = Object();
}

class EmployeeOperationInProgress extends EmployeeState {
  final EmployeeLoaded previous;
  const EmployeeOperationInProgress(this.previous);
  @override
  List<Object?> get props => [previous];
}

class EmployeeError extends EmployeeState {
  final String message;
  const EmployeeError(this.message);
  @override
  List<Object?> get props => [message];
}

class EmployeeValidationFailure extends EmployeeState {
  final Map<String, String> fieldErrors;
  final EmployeeLoaded? loaded;

  const EmployeeValidationFailure({
    required this.fieldErrors,
    this.loaded,
  });

  String get firstMessage => fieldErrors.values.first;

  @override
  List<Object?> get props => [fieldErrors, loaded];
}

class EmployeeOperationSuccess extends EmployeeState {
  final String message;
  final EmployeeLoaded loaded;
  const EmployeeOperationSuccess({required this.message, required this.loaded});
  @override
  List<Object?> get props => [message, loaded];
}
