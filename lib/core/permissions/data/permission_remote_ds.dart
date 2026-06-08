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

  /// Fetches the enabled/disabled state of all modules for [businessId].
  ///
  /// Returns a map of moduleCode → enabled.  An empty map means no rows exist
  /// yet (treat all modules as enabled until the owner configures them).
  Future<Map<String, bool>> fetchEnabledModules(String businessId) async {
    final rows = await _client
        .from('business_modules')
        .select('enabled, modules(code)')
        .eq('business_id', businessId);

    return {
      for (final row in rows)
        ((row['modules'] as Map<String, dynamic>)['code'] as String):
            (row['enabled'] as bool? ?? true),
    };
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

  /// Enables or disables a module for [businessId].
  ///
  /// Calls the `set_module_enabled` SECURITY DEFINER RPC which enforces
  /// owner/admin-only access server-side (bypasses the broken i_am_super_admin
  /// RLS gate) and resolves module_id from the code automatically.
  Future<void> setModuleEnabled(
    String businessId,
    String moduleCode,
    bool enabled,
  ) async {
    await _client.rpc('set_module_enabled', params: {
      'p_business_id': businessId,
      'p_module_code': moduleCode,
      'p_enabled': enabled,
    });
  }

  /// Returns business-wide permission overrides for [employeeId].
  ///
  /// Uses the `get_employee_permission_overrides` RPC so the client never
  /// needs to know internal permission UUIDs.
  ///
  /// Map value: `true` = explicit grant, `false` = explicit deny.
  /// A missing key means no override (role default applies).
  Future<Map<String, bool>> fetchUserPermissionOverrides(
    String employeeId,
  ) async {
    final dynamic result = await _client.rpc(
      'get_employee_permission_overrides',
      params: {'p_employee_id': employeeId},
    );

    if (result is! List) return {};
    return {
      for (final row in result)
        (row['permission_code'] as String): (row['is_granted'] as bool? ?? false),
    };
  }

  /// Upserts a business-wide permission override for [employeeId].
  ///
  /// Uses the `set_employee_permission_override` RPC which resolves
  /// permission_id, business_id, and granted_by automatically from the
  /// caller's session — owner/admin only.
  Future<void> setUserPermissionOverride(
    String employeeId,
    String permissionCode,
    bool granted,
  ) async {
    await _client.rpc(
      'set_employee_permission_override',
      params: {
        'p_employee_id': employeeId,
        'p_permission_code': permissionCode,
        'p_is_granted': granted,
      },
    );
  }

  /// Removes a business-wide override, reverting the employee to their role default.
  Future<void> removeUserPermissionOverride(
    String employeeId,
    String permissionCode,
  ) async {
    await _client.rpc(
      'set_employee_permission_override',
      params: {
        'p_employee_id': employeeId,
        'p_permission_code': permissionCode,
        'p_is_granted': null,
      },
    );
  }
}
