import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeesRemoteDs {
  final SupabaseClient client;
  EmployeesRemoteDs(this.client);

  Future<void> upsertEmployee({
    required String id,
    required String businessId,
    required String branchId,
    String? authUserId,
    required String employeeCode,
    required String fullName,
    required String email,
    String? phone,
    required String role,
    required String status,
    String? profileImageUrl,
    required DateTime hiredAt,
    DateTime? archivedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    await client.from('employees').upsert({
      'id': id,
      'business_id': businessId,
      'branch_id': branchId,
      'auth_user_id': authUserId,
      'employee_code': employeeCode,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'profile_image_url': profileImageUrl,
      'hired_at': hiredAt.toIso8601String(),
      'archived_at': archivedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    });
  }

  Future<void> updateEmployeeStatus({
    required String id,
    required String status,
    DateTime? archivedAt,
    required DateTime updatedAt,
  }) async {
    await client
        .from('employees')
        .update({
          'status': status,
          'archived_at': archivedAt?.toIso8601String(),
          'updated_at': updatedAt.toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteEmployee(String id) async {
    await client.from('employees').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getEmployeesByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('employees')
        .select()
        .eq('business_id', businessId)
        .order('full_name');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Creates a Supabase Auth account for the employee via RPC so they can
  /// log into the app.  Returns the new (or existing) `auth_user_id`, or
  /// `null` if the call fails (e.g. offline — the employee record still
  /// exists locally and can be linked to an auth account later).
  Future<String?> createAuthAccount({
    required String email,
    required String password,
  }) async {
    try {
      final result = await client.rpc(
        'create_employee_auth_account',
        params: {'p_email': email, 'p_password': password},
      ) as String?;
      return result;
    } catch (_) {
      return null;
    }
  }
}
