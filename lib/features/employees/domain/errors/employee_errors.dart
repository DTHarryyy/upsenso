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
