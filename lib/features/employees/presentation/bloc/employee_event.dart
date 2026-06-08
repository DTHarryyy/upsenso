import 'package:equatable/equatable.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';

abstract class EmployeeEvent extends Equatable {
  const EmployeeEvent();
  @override
  List<Object?> get props => [];
}

class LoadEmployees extends EmployeeEvent {
  final String businessId;
  final String? branchId;
  final String? roleName;
  final String? userId;
  final String? userName;

  const LoadEmployees({
    required this.businessId,
    this.branchId,
    this.roleName,
    this.userId,
    this.userName,
  });

  @override
  List<Object?> get props => [businessId, branchId, roleName];
}

class EmployeesUpdated extends EmployeeEvent {
  final List<Employee> employees;
  const EmployeesUpdated(this.employees);
  @override
  List<Object?> get props => [employees];
}

class AddEmployee extends EmployeeEvent {
  final String branchId;
  final String fullName;
  final String email;
  final String password;
  final String? roleId;
  final String? roleName;

  const AddEmployee({
    required this.branchId,
    required this.fullName,
    required this.email,
    required this.password,
    this.roleId,
    this.roleName,
  });

  @override
  List<Object?> get props => [fullName, email, branchId, roleId, roleName];
}

class UpdateEmployee extends EmployeeEvent {
  final String id;
  final String fullName;
  final String? roleId;
  final String? branchId;
  final bool? isActive;

  const UpdateEmployee({
    required this.id,
    required this.fullName,
    this.roleId,
    this.branchId,
    this.isActive,
  });

  @override
  List<Object?> get props => [id, fullName, roleId, branchId, isActive];
}

class ArchiveEmployee extends EmployeeEvent {
  final String id;
  const ArchiveEmployee(this.id);
  @override
  List<Object?> get props => [id];
}

class SuspendEmployee extends EmployeeEvent {
  final String id;
  const SuspendEmployee(this.id);
  @override
  List<Object?> get props => [id];
}

class ReactivateEmployee extends EmployeeEvent {
  final String id;
  const ReactivateEmployee(this.id);
  @override
  List<Object?> get props => [id];
}

class SearchEmployees extends EmployeeEvent {
  final String query;
  const SearchEmployees(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterEmployees extends EmployeeEvent {
  /// Filter by role name string (e.g. 'Cashier', 'Branch Manager'). Null = all.
  final String? roleFilter;

  /// Filter by active status. Null = all.
  final bool? isActiveFilter;

  final String? branchFilter;

  const FilterEmployees({
    this.roleFilter,
    this.isActiveFilter,
    this.branchFilter,
  });

  @override
  List<Object?> get props => [roleFilter, isActiveFilter, branchFilter];
}

class ClearEmployeeFilters extends EmployeeEvent {
  const ClearEmployeeFilters();
}
