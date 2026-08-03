import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeesRemoteDs {
  final SupabaseClient client;
  EmployeesRemoteDs(this.client);

  Future<void> upsertEmployee({
    required String id,
    required String businessId,
    String? userId,
    String? authUserId,
    required String fullName,
    String? email,
    String? roleId,
    String? roleName,
    bool isActive = true,
  }) async {
    await client.from('employees').upsert({
      'id': id,
      'business_id': businessId,
      'user_id': ?userId,
      'auth_user_id': ?authUserId,
      'full_name': fullName,
      'email': ?email,
      'role_id': ?roleId,
      'role_name': ?roleName,
      'is_active': isActive,
    });
  }

  /// Returns the business roles as a name (lowercased) -> id map so callers
  /// can resolve a display role name to its real UUID before writing.
  Future<Map<String, String>> getRolesByBusiness(String businessId) async {
    final response = await client
        .from('roles')
        .select('id, name')
        .eq('business_id', businessId);
    final rows = List<Map<String, dynamic>>.from(response as List);
    final map = <String, String>{};
    for (final row in rows) {
      final name = row['name']?.toString();
      final id = row['id']?.toString();
      if (name != null && id != null) map[name.toLowerCase().trim()] = id;
    }
    return map;
  }

  /// Assign an employee to a branch via the employee_branches join table.
  Future<void> assignBranch({
    required String employeeId,
    required String branchId,
  }) async {
    await client.from('employee_branches').upsert({
      'employee_id': employeeId,
      'branch_id': branchId,
    });
  }

  /// Remove an employee's branch assignment.
  Future<void> removeBranch({
    required String employeeId,
    required String branchId,
  }) async {
    await client
        .from('employee_branches')
        .delete()
        .eq('employee_id', employeeId)
        .eq('branch_id', branchId);
  }

  Future<void> setActive({required String id, required bool isActive}) async {
    await client.from('employees').update({'is_active': isActive}).eq('id', id);
  }

  Future<void> deleteEmployee(String id) async {
    await client.from('employees').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getEmployeesByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('employees')
        // Disambiguate: employees has two paths to roles (direct role_id FK,
        // and the many-to-many employee_roles junction used by permissions).
        // We want the single direct role for display, not the junction.
        .select(
          '*, roles!employees_role_id_fkey(name), employee_branches(branch_id)',
        )
        .eq('business_id', businessId)
        .order('full_name');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Emails the new employee their login credentials via the
  /// `send-employee-credentials` edge function. Throws on any non-success
  /// response so the caller can tell whether delivery actually happened — the
  /// account already exists either way, so treating this as non-fatal is the
  /// *caller's* decision, not something to hide here.
  Future<void> sendCredentialsEmail({
    required String email,
    required String password,
    required String fullName,
    String? businessName,
  }) async {
    try {
      final res = await client.functions.invoke(
        'send-employee-credentials',
        body: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'businessName': ?businessName,
        },
      );
      final data = res.data;
      if (res.status == 200 && data is Map && data['ok'] == true) return;
      throw Exception(_stageMessage(data, res.status));
    } on FunctionException catch (e) {
      // supabase_flutter throws this for any non-2xx before the 200-check
      // above ever runs — the real reason (our own {error, stage} body) only
      // survives on `e.details`. Without this the caller only ever sees an
      // opaque FunctionException, which is what made this silently
      // undiagnosable in the field.
      throw Exception(_stageMessage(e.details, e.status));
    }
  }

  String _stageMessage(dynamic data, int status) {
    final map = data is Map ? data : const {};
    final stage = map['stage']?.toString();
    final error = map['error']?.toString();
    debugPrint(
      '[EmployeesRemoteDs] send-employee-credentials failed '
      '(status: $status, stage: $stage): $error',
    );
    return error ?? 'send-employee-credentials failed ($status)';
  }

  /// Creates a Supabase Auth user for the employee and returns the new UUID.
  ///
  /// Throws on any error (duplicate email, network failure, auth failure).
  /// The caller is responsible for catching and surfacing the error — the
  /// password is only available at call time and cannot be stored for retry.
  Future<String> createAuthAccount({
    required String email,
    required String password,
    String? businessId,
    String? branchId,
    String? fullName,
    String? roleId,
  }) async {
    final params = <String, dynamic>{
      'p_email': email,
      'p_password': password,
    };
    if (businessId != null) params['p_business_id'] = businessId;
    if (branchId != null) params['p_branch_id'] = branchId;
    if (fullName != null) params['p_full_name'] = fullName;
    if (roleId != null) params['p_role_id'] = roleId;
    final result =
        await client.rpc('create_employee_auth_account', params: params)
            as String;
    return result;
  }
}
