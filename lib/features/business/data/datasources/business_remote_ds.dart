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

  /// Create user with Business Owner role for a business
  Future<Map<String, dynamic>> createUserForBusiness({
    required String businessId,
    required String userId,
    required String email,
    required String? fullName,
    required String ownerRoleId,
  }) async {
    final defaultFullName = fullName ?? _extractNameFromEmail(email);

    final userData = {
      'id': userId,
      'business_id': businessId,
      'email': email,
      'full_name': defaultFullName,
      'role_id': ownerRoleId,
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

  /// Apply the business template server-side (atomic, idempotent).
  ///
  /// Calls the `apply_business_template` Postgres function which:
  ///   - Creates the 4 standard roles with correct permission maps
  ///   - Seeds product categories from the template's default_categories list
  ///   - Initialises receipt_settings for the business
  ///
  /// Returns the Business Owner role UUID so the caller can link the owner.
  Future<String> applyBusinessTemplate({
    required String businessId,
    required String templateId,
  }) async {
    final result = await client.rpc(
      'apply_business_template',
      params: {'p_business_id': businessId, 'p_template_id': templateId},
    );
    return result as String;
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

  /// Mirror the unified business logo URL onto the business row so the app
  /// shell and any server-side reads stay in sync. The canonical local source
  /// of truth is receipt_settings; this just keeps businesses.logo_url current.
  Future<void> updateLogoUrl({
    required String businessId,
    required String url,
  }) async {
    await client
        .from('businesses')
        .update({'logo_url': url})
        .eq('id', businessId);
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

  /// Upsert a branch (safe for re-sync — won't fail on duplicate key).
  Future<Map<String, dynamic>> createBranch({
    required String id,
    required String businessId,
    required String name,
    String? location,
  }) async {
    final response = await client
        .from('branches')
        .upsert({
          'id': id,
          'business_id': businessId,
          'name': name,
          'location': location,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Update an existing branch on Supabase.
  Future<void> updateBranch({
    required String id,
    required String name,
    String? location,
  }) async {
    await client
        .from('branches')
        .update({'name': name, 'location': location})
        .eq('id', id);
  }

  /// Delete a branch from Supabase.
  Future<void> deleteBranch(String id) async {
    await client.from('branches').delete().eq('id', id);
  }

  /// Upsert a single category to Supabase (safe for re-sync).
  Future<void> createCategory({
    required String id,
    required String businessId,
    required String name,
  }) async {
    await client.from('categories').upsert({
      'id': id,
      'business_id': businessId,
      'name': name,
    });
  }

  /// Update an existing category on Supabase.
  Future<void> updateCategory({
    required String id,
    required String name,
  }) async {
    await client
        .from('categories')
        .update({'name': name})
        .eq('id', id);
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
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch all branches for a business (used by Business Owner branch picker)
  Future<List<Map<String, dynamic>>> getActiveBranchesByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('branches')
        .select('id, name, business_id, location')
        .eq('business_id', businessId)
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch one branch by ID
  Future<Map<String, dynamic>?> getActiveBranchById(String branchId) async {
    final response = await client
        .from('branches')
        .select('id, name, business_id, location')
        .eq('id', branchId)
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
