import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/features/employees/domain/errors/employee_errors.dart';

/// Validates employee data against the local Drift database.
///
/// All checks are fully offline — no network access is required.
/// Intended to be called from the repository layer before any write.
class EmployeeValidationService {
  final EmployeesDao _dao;

  const EmployeeValidationService(this._dao);

  /// Checks that [email] and (optionally) [phone] are not already in use by
  /// another employee within [businessId].
  ///
  /// Pass [excludeId] when editing an existing employee so their own values
  /// do not trigger a false positive.
  ///
  /// Throws [EmployeeDuplicateException] if one or more conflicts are found.
  Future<void> validateNoDuplicates({
    required String businessId,
    required String email,
    String? phone,
    String? excludeId,
  }) async {
    final errors = <String, String>{};

    final emailConflict = await _dao.findByEmail(
      businessId,
      email,
      excludeId: excludeId,
    );
    if (emailConflict != null) {
      errors['email'] =
          'Email is already registered to ${emailConflict.fullName}';
    }

    if (phone != null && phone.isNotEmpty) {
      final phoneConflict = await _dao.findByPhone(
        businessId,
        phone,
        excludeId: excludeId,
      );
      if (phoneConflict != null) {
        errors['phone'] =
            'Phone number is already registered to ${phoneConflict.fullName}';
      }
    }

    if (errors.isNotEmpty) throw EmployeeDuplicateException(errors);
  }
}
