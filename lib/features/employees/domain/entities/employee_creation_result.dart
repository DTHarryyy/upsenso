/// Outcome of creating an employee's login account, returned so the UI can
/// confirm delivery of their auto-generated password — or, if the email
/// failed, hand it over another way.
class EmployeeCreationResult {
  final String employeeId;
  final String email;
  final bool credentialsEmailed;

  /// Only set when [credentialsEmailed] is false — the creator needs it to
  /// share access manually. Never persisted; held in memory for one dialog.
  final String? temporaryPassword;

  const EmployeeCreationResult({
    required this.employeeId,
    required this.email,
    required this.credentialsEmailed,
    this.temporaryPassword,
  });
}
