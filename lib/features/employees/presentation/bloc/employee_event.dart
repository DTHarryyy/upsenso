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
  final String? phone;
  final EmployeeRole role;
  final DateTime hiredAt;
  final String password;
  final String? profileImageUrl;

  const AddEmployee({
    required this.branchId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.hiredAt,
    required this.password,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [fullName, email, branchId, role];
}

class UpdateEmployee extends EmployeeEvent {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String branchId;
  final EmployeeRole role;
  final String? profileImageUrl;

  const UpdateEmployee({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.branchId,
    required this.role,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [id, fullName, email, branchId, role];
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
  final EmployeeRole? roleFilter;
  final EmployeeStatus? statusFilter;
  final String? branchFilter;

  const FilterEmployees({
    this.roleFilter,
    this.statusFilter,
    this.branchFilter,
  });

  @override
  List<Object?> get props => [roleFilter, statusFilter, branchFilter];
}

class ClearEmployeeFilters extends EmployeeEvent {
  const ClearEmployeeFilters();
}
