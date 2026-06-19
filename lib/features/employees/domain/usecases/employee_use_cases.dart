import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/domain/repositories/i_employees_repository.dart';

class LoadEmployeesUseCase {
  final IEmployeesRepository _repository;
  LoadEmployeesUseCase(this._repository);
  Stream<List<Employee>> call(String businessId) =>
      _repository.watchEmployees(businessId);
}

class AddEmployeeUseCase {
  final IEmployeesRepository _repository;
  AddEmployeeUseCase(this._repository);

  Future<void> call({
    required String businessId,
    required String branchId,
    required String fullName,
    required String email,
    required String password,
    String? roleId,
    bool isActive = true,
  }) => _repository.addEmployee(
    businessId: businessId,
    branchId: branchId,
    fullName: fullName,
    email: email,
    password: password,
    roleId: roleId,
    isActive: isActive,
  );
}

class UpdateEmployeeUseCase {
  final IEmployeesRepository _repository;
  UpdateEmployeeUseCase(this._repository);

  Future<void> call({
    required String id,
    required String fullName,
    String? roleId,
    String? roleName,
    String? branchId,
    bool? isActive,
  }) => _repository.updateEmployee(
    id: id,
    fullName: fullName,
    roleId: roleId,
    roleName: roleName,
    branchId: branchId,
    isActive: isActive,
  );
}

class ArchiveEmployeeUseCase {
  final IEmployeesRepository _repository;
  ArchiveEmployeeUseCase(this._repository);
  Future<void> call(String id) => _repository.archiveEmployee(id);
}

class SuspendEmployeeUseCase {
  final IEmployeesRepository _repository;
  SuspendEmployeeUseCase(this._repository);
  Future<void> call(String id) => _repository.suspendEmployee(id);
}

class ReactivateEmployeeUseCase {
  final IEmployeesRepository _repository;
  ReactivateEmployeeUseCase(this._repository);
  Future<void> call(String id) => _repository.reactivateEmployee(id);
}
