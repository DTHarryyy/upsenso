import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/device/device_identity_service.dart';

class BusinessRemoteDs {
  final SupabaseClient client;
  final DeviceIdentityService _identity;
  BusinessRemoteDs(this.client, this._identity);

  /// Fetch all business templates
  Future<List<Map<String, dynamic>>> getBusinessTemplates() async {
    final response = await client
        .from('business_templates')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // NOTE: createBusiness / applyBusinessTemplate / createUserForBusiness were
  // removed on 2026-07-31. Provisioning a business piecemeal over several
  // auto-committing round-trips is what allowed a half-built tenant to exist at
  // all; createBusinessOnboarding below does the whole thing in one
  // transaction. Do not reintroduce a partial path.

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

  /// Get business by owner ID.
  ///
  /// Ordered + limited rather than a bare `.maybeSingle()`: that form THROWS on
  /// more than one row, so the 2026-07-26 duplicate-signup bug left the affected
  /// account unable to start online at all. A unique index now prevents
  /// duplicates, but this must never be the thing that bricks a user again.
  Future<Map<String, dynamic>?> getBusinessByOwner(String ownerId) async {
    final response = await client
        .from('businesses')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    return response != null ? Map<String, dynamic>.from(response) : null;
  }

  /// Provision a whole business in ONE transaction: business + branch + roles +
  /// permissions + modules + categories + receipt settings + the owner's user
  /// row. Replaces the old four-round-trip sequence, where a failure part-way
  /// left a committed but unusable business behind (and a retry made another).
  ///
  /// The RPC is idempotent per owner — a retry returns the existing business
  /// rather than creating a second one. Ids are client-minted so the local
  /// offline-first rows keep their identity.
  Future<Map<String, dynamic>> createBusinessOnboarding({
    required String businessId,
    required String name,
    required String templateId,
    required String branchId,
    required String branchName,
    String? fullName,
    String? email,
  }) async {
    // Same display-name fallback the old users upsert applied, kept so an owner
    // without a full_name still gets a readable name rather than null.
    final resolvedFullName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName
        : (email != null && email.isNotEmpty
            ? _extractNameFromEmail(email)
            : null);

    // Identity failure must never block signup (same rule as the old path).
    String? deviceUid;
    try {
      deviceUid = await _identity.getDeviceUid();
    } catch (e, st) {
      debugPrint('[BusinessRemoteDs] Error in onboarding device uid: $e\n$st');
    }

    final result = await client.rpc('create_business_onboarding', params: {
      'p_business_id': businessId,
      'p_name': name,
      'p_template_id': templateId,
      'p_branch_id': branchId,
      'p_branch_name': branchName,
      'p_full_name': resolvedFullName,
      'p_signup_device_uid': deviceUid,
    });

    return Map<String, dynamic>.from(result as Map);
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
