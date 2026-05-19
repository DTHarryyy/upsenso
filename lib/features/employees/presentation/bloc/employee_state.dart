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
  final EmployeeRole? roleFilter;
  final EmployeeStatus? statusFilter;
  final String? branchFilter;

  const EmployeeLoaded({
    required this.allEmployees,
    required this.displayEmployees,
    this.searchQuery = '',
    this.roleFilter,
    this.statusFilter,
    this.branchFilter,
  });

  int get activeCount =>
      allEmployees.where((e) => e.status == EmployeeStatus.active).length;

  int get suspendedCount =>
      allEmployees.where((e) => e.status == EmployeeStatus.suspended).length;

  int get archivedCount =>
      allEmployees.where((e) => e.status == EmployeeStatus.archived).length;

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      roleFilter != null ||
      statusFilter != null ||
      branchFilter != null;

  EmployeeLoaded copyWith({
    List<Employee>? allEmployees,
    List<Employee>? displayEmployees,
    String? searchQuery,
    Object? roleFilter = _sentinel,
    Object? statusFilter = _sentinel,
    Object? branchFilter = _sentinel,
  }) {
    return EmployeeLoaded(
      allEmployees: allEmployees ?? this.allEmployees,
      displayEmployees: displayEmployees ?? this.displayEmployees,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: identical(roleFilter, _sentinel)
          ? this.roleFilter
          : roleFilter as EmployeeRole?,
      statusFilter: identical(statusFilter, _sentinel)
          ? this.statusFilter
          : statusFilter as EmployeeStatus?,
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

/// Emitted when creation or update is rejected because a duplicate value
/// (email, phone) was detected in the local database.
///
/// [fieldErrors] maps each conflicting field name to a human-readable message.
/// [loaded] preserves the previous list state so the page does not go blank.
class EmployeeValidationFailure extends EmployeeState {
  final Map<String, String> fieldErrors;
  final EmployeeLoaded? loaded;

  const EmployeeValidationFailure({
    required this.fieldErrors,
    this.loaded,
  });

  /// The first conflict message, suitable for a snackbar / toast.
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
