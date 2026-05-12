import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessRemoteDs {
  final SupabaseClient client;
  BusinessRemoteDs(this.client);

  /// Fetch all business templates
  Future<List<Map<String, dynamic>>> getBusinessTemplates() async {
    final response = await client
        .from('business_templates')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new business (upsert so re-sync never fails with duplicate key).
  Future<Map<String, dynamic>> createBusiness({
    required String id,
    required String name,
    required String ownerId,
    required String templateId,
  }) async {
    final response = await client
        .from('businesses')
        .upsert({
          'id': id,
          'name': name,
          'owner_id': ownerId,
          'template_id': templateId,
          'is_active': true,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Create user with super admin role for a business
  Future<Map<String, dynamic>> createUserForBusiness({
    required String businessId,
    required String userId,
    required String email,
    required String? fullName,
    required String superAdminRoleId,
  }) async {
    final defaultFullName = fullName ?? _extractNameFromEmail(email);

    final userData = {
      'id': userId,
      'business_id': businessId,
      'email': email,
      'full_name': defaultFullName,
      'role_id': superAdminRoleId,
      'is_active': true,
    };

    // Upsert because the auth trigger may have already created a minimal row
    // (id + email) when the user signed up. We update it with full business context.
    final response = await client
        .from('users')
        .upsert(userData, onConflict: 'id')
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Extract first name from email (part before the first separator or @).
  /// e.g. "john.doe@gmail.com" → "John", "janedoe@mail.com" → "Janedoe"
  String _extractNameFromEmail(String email) {
    final username = email.split('@')[0];
    final firstName = username
        .split(RegExp(r'[._\-]'))
        .firstWhere((p) => p.isNotEmpty, orElse: () => username);
    if (firstName.isEmpty) return username;
    return firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
  }

  /// Get or create super admin role for a business
  Future<String> getSuperAdminRoleId({
    required String businessId,
    required List<Map<String, dynamic>> templateRoles,
  }) async {
    // Try to find existing super admin role
    final existing = await client
        .from('roles')
        .select('id')
        .eq('business_id', businessId)
        .eq('name', 'Super Admin')
        .maybeSingle();

    if (existing != null) {
      return existing['id'];
    }

    // Create super admin role from template
    final superAdminTemplate = templateRoles.firstWhere(
      (role) => role['name'] == 'Super Admin',
      orElse: () => {
        'name': 'Super Admin',
        'permissions': {'all': true},
      },
    );

    final created = await client
        .from('roles')
        .insert({
          'business_id': businessId,
          'name': superAdminTemplate['name'],
          'permissions': superAdminTemplate['permissions'] ?? {'all': true},
        })
        .select()
        .single();

    return created['id'];
  }

  /// Get business by owner ID
  Future<Map<String, dynamic>?> getBusinessByOwner(String ownerId) async {
    final response = await client
        .from('businesses')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();

    return response != null ? Map<String, dynamic>.from(response) : null;
  }

  /// Get business by ID
  Future<Map<String, dynamic>?> getBusinessById(String businessId) async {
    final response = await client
        .from('businesses')
        .select()
        .eq('id', businessId)
        .maybeSingle();

    return response != null ? Map<String, dynamic>.from(response) : null;
  }

  /// Create a new branch
  Future<Map<String, dynamic>> createBranch({
    required String id,
    required String businessId,
    required String name,
    String? address,
    String? phone,
  }) async {
    final response = await client
        .from('branches')
        .insert({
          'id': id,
          'business_id': businessId,
          'name': name,
          'address': address,
          'phone': phone,
          'is_active': true,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Upsert a single category to Supabase (safe for re-sync).
  Future<void> createCategory({
    required String id,
    required String businessId,
    required String name,
    required int sortOrder,
  }) async {
    await client.from('categories').upsert({
      'id': id,
      'business_id': businessId,
      'name': name,
      'sort_order': sortOrder,
    });
  }

  /// Update an existing category on Supabase.
  Future<void> updateCategory({
    required String id,
    required String name,
    required int sortOrder,
  }) async {
    await client.from('categories').update({
      'name': name,
      'sort_order': sortOrder,
    }).eq('id', id);
  }

  /// Delete a category from Supabase.
  Future<void> deleteCategory(String id) async {
    await client.from('categories').delete().eq('id', id);
  }

  /// Fetch all categories for a business (for pull sync).
  Future<List<Map<String, dynamic>>> getCategoriesByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('categories')
        .select()
        .eq('business_id', businessId)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch all active branches for a business (used by Super Admin branch picker)
  Future<List<Map<String, dynamic>>> getActiveBranchesByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('branches')
        .select('id, name, business_id, is_active')
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch one active branch by ID (used by Admin restricted to assigned branch)
  Future<Map<String, dynamic>?> getActiveBranchById(String branchId) async {
    final response = await client
        .from('branches')
        .select('id, name, business_id, is_active')
        .eq('id', branchId)
        .eq('is_active', true)
        .maybeSingle();

    return response != null ? Map<String, dynamic>.from(response) : null;
  }

  /// Best-effort link of the signed-up user to their default branch.
  /// Retries briefly because user row creation can lag behind business creation.
  Future<bool> assignUserBranch({
    required String userId,
    required String branchId,
  }) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final updatedRows = List<Map<String, dynamic>>.from(
          await client
              .from('users')
              .update({'branch_id': branchId})
              .eq('id', userId)
              .select('id')
              .limit(1),
        );

        if (updatedRows.isNotEmpty) {
          return true;
        }
      } catch (_) {
        return false;
      }

      if (attempt < 7) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }

    return false;
  }

  /// Verify user was created by trigger
  Future<List<Map<String, dynamic>>> getUserByBusinessId(
    String businessId,
  ) async {
    final response = await client
        .from('users')
        .select()
        .eq('business_id', businessId);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Verify roles were created by trigger
  Future<List<Map<String, dynamic>>> getRolesByBusinessId(
    String businessId,
  ) async {
    final response = await client
        .from('roles')
        .select()
        .eq('business_id', businessId);

    return List<Map<String, dynamic>>.from(response);
  }
}
