/// Thrown when employee creation or update would create a duplicate record
/// within the same business (duplicate email, phone, etc.).
///
/// [fieldErrors] maps each conflicting field name (e.g. `'email'`, `'phone'`)
/// to a human-readable message identifying the existing record.
class EmployeeDuplicateException implements Exception {
  final Map<String, String> fieldErrors;

  const EmployeeDuplicateException(this.fieldErrors);

  /// Returns the first conflict message, suitable for a snackbar / toast.
  String get firstMessage => fieldErrors.values.first;

  @override
  String toString() => 'EmployeeDuplicateException: $fieldErrors';
}

/// Thrown when an action is blocked because the target employee is a protected
/// account (Owner / Super Admin) that cannot be removed or deactivated.
class EmployeeProtectedException implements Exception {
  final String message;

  const EmployeeProtectedException([
    this.message = 'Owners and Super Admins cannot be removed or suspended.',
  ]);

  @override
  String toString() => 'EmployeeProtectedException: $message';
}

/// Thrown when adding (or reactivating) an employee would exceed the plan's
/// seat limit. Client-side courtesy check — the server RPC enforces the same
/// cap authoritatively. Suspending an employee frees a seat immediately.
class EmployeeSeatLimitException implements Exception {
  final String message;

  const EmployeeSeatLimitException([
    this.message =
        'Your plan\'s seat limit is reached. Add a seat add-on or upgrade '
        'to invite more staff.',
  ]);

  @override
  String toString() => message;
}
