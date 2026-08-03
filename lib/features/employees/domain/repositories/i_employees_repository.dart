import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/domain/entities/employee_creation_result.dart';

abstract class IEmployeesRepository {
  Stream<List<Employee>> watchEmployees(String businessId);
  Future<List<Employee>> loadEmployees(String businessId);
  Future<Employee?> getById(String id);

  /// Generates the employee's temporary password internally — callers never
  /// see or choose it. See [EmployeeCreationResult] for how delivery is
  /// reported back.
  Future<EmployeeCreationResult> addEmployee({
    required String businessId,
    required String branchId,
    required String fullName,
    required String email,
    String? roleId,
    String? roleName,
    bool isActive = true,
  });

  Future<void> updateEmployee({
    required String id,
    required String fullName,
    String? roleId,
    String? roleName,
    String? branchId,
    bool? isActive,
  });

  Future<void> archiveEmployee(String id);
  Future<void> suspendEmployee(String id);
  Future<void> reactivateEmployee(String id);
}
