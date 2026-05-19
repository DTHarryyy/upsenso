import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase data source for the [employee_permissions] table.
///
/// The app calls [fetchMyPermissions] (via RPC) on login to load the
/// per-employee permission matrix.  The result is cached in Drift by
/// [EmployeePermissionsDao].
class PermissionRemoteDs {
  final SupabaseClient _client;

  const PermissionRemoteDs(this._client);

  /// Calls the `get_my_permissions()` Supabase RPC function, which returns
  /// the JSONB permissions for the currently authenticated user.
  ///
  /// Returns an empty map when the user has no permissions row yet.
  /// Throws on network/auth errors.
  Future<({Map<String, bool> permissions, String? employeeId})>
  fetchMyPermissions() async {
    // Resolve the employee record so we can store the employeeId in Drift.
    final employeeRow = await _client
        .from('employees')
        .select('id')
        .eq('auth_user_id', _client.auth.currentUser!.id)
        .maybeSingle();

    final employeeId = employeeRow?['id'] as String?;

    // Use the RPC helper for a single, RLS-safe permissions fetch.
    final dynamic result = await _client.rpc('get_my_permissions');

    Map<String, bool> permissions = {};
    if (result is Map) {
      permissions = (result as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v == true),
      );
    }

    return (permissions: permissions, employeeId: employeeId);
  }

  /// Saves a modified permissions map back to Supabase.
  ///
  /// Requires the caller to have `admin_write_permissions` RLS policy.
  Future<void> savePermissions(
    String employeeId,
    Map<String, bool> permissions,
  ) async {
    await _client.from('employee_permissions').upsert({
      'employee_id': employeeId,
      'permissions': permissions,
    }, onConflict: 'employee_id');
  }
}
