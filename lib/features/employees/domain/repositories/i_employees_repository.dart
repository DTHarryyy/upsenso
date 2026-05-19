import 'package:pos/features/employees/domain/entities/employee.dart';

abstract class IEmployeesRepository {
  Stream<List<Employee>> watchEmployees(String businessId);
  Future<List<Employee>> loadEmployees(String businessId);
  Future<Employee?> getById(String id);

  Future<void> addEmployee({
    required String businessId,
    required String branchId,
    required String fullName,
    required String email,
    required String? phone,
    required EmployeeRole role,
    required DateTime hiredAt,
    required String password,
    String? authUserId,
    String? profileImageUrl,
  });

  Future<void> updateEmployee({
    required String id,
    required String fullName,
    required String email,
    required String? phone,
    required String branchId,
    required EmployeeRole role,
    String? profileImageUrl,
  });

  Future<void> archiveEmployee(String id);
  Future<void> suspendEmployee(String id);
  Future<void> reactivateEmployee(String id);
}
