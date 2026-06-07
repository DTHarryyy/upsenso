import 'package:pos/core/database/daos/employees_dao.dart';

/// Validates employee data against the local Drift database.
class EmployeeValidationService {
  final EmployeesDao _dao;
  const EmployeeValidationService(this._dao);

  /// Returns true if any active employee in [businessId] already has [authUserId].
  Future<bool> authUserIdInUse(String businessId, String authUserId) async {
    final rows = await _dao.getByBusinessId(businessId);
    return rows.any((r) => r.authUserId == authUserId);
  }
}
