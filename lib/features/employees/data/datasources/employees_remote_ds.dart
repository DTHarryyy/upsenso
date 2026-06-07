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
    String? roleId,
    bool isActive = true,
  }) async {
    await client.from('employees').upsert({
      'id': id,
      'business_id': businessId,
      'user_id': ?userId,
      'auth_user_id': ?authUserId,
      'full_name': fullName,
      'role_id': ?roleId,
      'is_active': isActive,
    });
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
        .select('*, roles(name), employee_branches(branch_id)')
        .eq('business_id', businessId)
        .order('full_name');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Creates a Supabase Auth account for the employee via RPC.
  /// Returns the new auth_user_id, or null if offline / RPC unavailable.
  Future<String?> createAuthAccount({
    required String email,
    required String password,
    String? employeeId,
    String? businessId,
    String? branchId,
    String? fullName,
    String? roleId,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_email': email,
        'p_password': password,
      };
      if (employeeId != null) params['p_employee_id'] = employeeId;
      if (businessId != null) params['p_business_id'] = businessId;
      if (branchId != null) params['p_branch_id'] = branchId;
      if (fullName != null) params['p_full_name'] = fullName;
      if (roleId != null) params['p_role_id'] = roleId;
      final result =
          await client.rpc('create_employee_auth_account', params: params)
              as String?;
      return result;
    } catch (_) {
      return null;
    }
  }
}
