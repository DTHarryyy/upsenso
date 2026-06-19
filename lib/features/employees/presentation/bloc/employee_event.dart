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

  /// Role names the current actor is allowed to assign. When non-null the bloc
  /// rejects any [roleName] outside this set to stop privilege escalation.
  final List<String>? allowedRoleNames;

  const AddEmployee({
    required this.branchId,
    required this.fullName,
    required this.email,
    required this.password,
    this.roleId,
    this.roleName,
    this.allowedRoleNames,
  });

  @override
  List<Object?> get props =>
      [fullName, email, branchId, roleId, roleName, allowedRoleNames];
}

class UpdateEmployee extends EmployeeEvent {
  final String id;
  final String fullName;
  final String? roleId;
  final String? roleName;
  final String? branchId;
  final bool? isActive;

  /// See [AddEmployee.allowedRoleNames].
  final List<String>? allowedRoleNames;

  const UpdateEmployee({
    required this.id,
    required this.fullName,
    this.roleId,
    this.roleName,
    this.branchId,
    this.isActive,
    this.allowedRoleNames,
  });

  @override
  List<Object?> get props =>
      [id, fullName, roleId, roleName, branchId, isActive, allowedRoleNames];
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
  final String? roleFilter;
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

class SetRoleFilter extends EmployeeEvent {
  final String? role;
  const SetRoleFilter(this.role);
  @override
  List<Object?> get props => [role];
}

class SetStatusFilter extends EmployeeEvent {
  final bool? isActive;
  const SetStatusFilter(this.isActive);
  @override
  List<Object?> get props => [isActive];
}

class SetBranchFilter extends EmployeeEvent {
  final String? branchId;
  const SetBranchFilter(this.branchId);
  @override
  List<Object?> get props => [branchId];
}

class ClearEmployeeFilters extends EmployeeEvent {
  const ClearEmployeeFilters();
}
