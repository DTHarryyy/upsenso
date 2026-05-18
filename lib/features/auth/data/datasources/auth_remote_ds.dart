import 'package:flutter/foundation.dart';
import 'package:pos/core/env/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AuthRemoteDs {
  final SupabaseClient client;
  AuthRemoteDs(this.client);

  User? currentUser() => client.auth.currentUser;

  Stream<AuthState> onAuthStateChange() => client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle({required String mobileRedirectTo}) async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? AppEnv.webOauthRedirectUrl : mobileRedirectTo,
      // On web, force a same-tab redirect so the Flutter canvas doesn't
      // retain keyboard focus and block typing in the OAuth popup/new tab.
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.inAppWebView
          : LaunchMode.externalApplication,
    );
  }

  Future<void> signInWithFacebook({required String mobileRedirectTo}) async {
    await client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? AppEnv.webOauthRedirectUrl : mobileRedirectTo,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.inAppWebView
          : LaunchMode.externalApplication,
    );
  }

  Future<AuthResponse> signUp(String email, String password) {
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> sendSignUpOtp(String email) async {
    await client.auth.signInWithOtp(email: email, shouldCreateUser: true);
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      // Try to send OTP without creating user
      // If user exists, this will succeed; if not, it will throw an error
      await client.auth.signInWithOtp(email: email, shouldCreateUser: false);
      return true; // User exists
    } catch (e) {
      if (e is AuthException) {
        final msg = e.message.toLowerCase();

        // If error indicates user doesn't exist, return false
        if (msg.contains('not found') ||
            msg.contains('does not exist') ||
            msg.contains('no user') ||
            msg.contains('user not found')) {
          return false; // User doesn't exist
        }

        // If it's a configuration error (signups disabled, email provider, etc.),
        // return false to proceed with signup which will catch the actual error
        if (msg.contains('signups not allowed') ||
            msg.contains('signup is disabled') ||
            msg.contains('email signups are disabled') ||
            msg.contains('email provider') ||
            msg.contains('smtp') ||
            msg.contains('disabled')) {
          return false; // Can't verify, let signup process handle it
        }
      }

      // For any other error, return false to let the signup flow handle it
      return false;
    }
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  /// Update user metadata with full name extracted from email
  Future<void> updateUserMetadata({
    required String email,
    String? fullName,
  }) async {
    final defaultFullName = fullName ?? _extractNameFromEmail(email);
    await client.auth.updateUser(
      UserAttributes(data: {'full_name': defaultFullName}),
    );
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

  /// Upload avatar image to Supabase Storage and return the public URL.
  Future<String> uploadAvatar(List<int> bytes, String userId) async {
    final path = '$userId/avatar.jpg';
    await client.storage
        .from('avatars')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    final url = client.storage.from('avatars').getPublicUrl(path);
    // Bust the cache by appending a timestamp query param
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updateAvatarUrl(String userId, String avatarUrl) async {
    await client.auth.updateUser(
      UserAttributes(data: {'avatar_url': avatarUrl}),
    );
    // Best-effort: also persist to public.users so other parts of the app
    // (staff lists, receipts, etc.) can read the avatar without going through auth.
    try {
      await client
          .from('users')
          .update({'avatar_url': avatarUrl})
          .eq('id', userId);
    } catch (_) {
      // Non-fatal: public.users may not yet have the avatar_url column.
    }
  }

  Future<void> signOut() => client.auth.signOut();

  /// Send password reset OTP to email
  Future<void> sendPasswordResetOtp(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Verify password reset OTP
  Future<AuthResponse> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) {
    return client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  /// Update password after OTP verification
  Future<void> updatePasswordAfterReset(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<Map<String, dynamic>?> _getUserBusinessContextViaRpc() async {
    try {
      final raw = await client.rpc('get_my_business_context');

      final rows = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final row in raw) {
          if (row is Map) {
            rows.add(Map<String, dynamic>.from(row));
          }
        }
      } else if (raw is Map) {
        rows.add(Map<String, dynamic>.from(raw));
      }

      if (rows.isEmpty) {
        return null;
      }

      final row = rows.first;
      final fullName =
          row['full_name']?.toString() ?? row['fu l_name']?.toString();

      final result = {
        'business_id': row['business_id']?.toString(),
        'role_id': row['role_id']?.toString(),
        'role_name': row['role_name']?.toString(),
        'business_name': row['business_name']?.toString(),
        'branch_id': row['branch_id']?.toString(),
        'branch_name': row['branch_name']?.toString(),
        'full_name': fullName,
        'template_id': row['template_id']?.toString(),
        'template_name': row['template_name']?.toString(),
      };

      return result;
    } catch (_) {
      return null;
    }
  }

  /// Fetch user's business context: businessId, roleId, businessName
  Future<Map<String, dynamic>?> getUserBusinessContext(String userId) async {
    try {
      final viaRpc = await _getUserBusinessContextViaRpc();
      if (viaRpc != null) {
        return viaRpc;
      }

      final current = client.auth.currentUser;
      if (current == null) {
        return null;
      }

      Map<String, dynamic>? businessRow;

      String? businessId;
      String? roleId;
      final fullName =
          current.userMetadata?['full_name']?.toString() ??
          _extractNameFromEmail(current.email ?? '');

      // Fallback path without `users` table access: infer context from owned business.
      final businessByOwnerRows = List<Map<String, dynamic>>.from(
        await client
            .from('businesses')
            .select('id, name, template_id')
            .eq('owner_id', current.id)
            .order('created_at', ascending: false)
            .limit(1),
      );

      if (businessByOwnerRows.isNotEmpty) {
        businessRow = businessByOwnerRows.first;
        businessId = businessRow['id']?.toString();
      }

      // Final fallback: owner is typically Super Admin for created business.
      if (businessId != null) {
        final superAdminRoleRows = List<Map<String, dynamic>>.from(
          await client
              .from('roles')
              .select('id')
              .eq('business_id', businessId)
              .eq('name', 'Super Admin')
              .limit(1),
        );

        if (superAdminRoleRows.isNotEmpty) {
          roleId = superAdminRoleRows.first['id']?.toString();
        }
      }

      final businessName = businessRow?['name']?.toString();
      final templateId = businessRow?['template_id']?.toString();

      // Fetch template name (business category) if we have a templateId
      String? templateName;
      if (templateId != null) {
        try {
          final templateRows = List<Map<String, dynamic>>.from(
            await client
                .from('business_templates')
                .select('name')
                .eq('id', templateId)
                .limit(1),
          );
          if (templateRows.isNotEmpty) {
            templateName = templateRows.first['name']?.toString();
          }
        } catch (_) {
          // Template name is optional; never fail the whole context fetch.
        }
      }

      // Fetch role name if we have roleId
      String? roleName;
      if (roleId != null) {
        try {
          final roleRows = List<Map<String, dynamic>>.from(
            await client.from('roles').select('name').eq('id', roleId).limit(1),
          );
          if (roleRows.isNotEmpty) {
            roleName = roleRows.first['name']?.toString();
          }
        } catch (_) {
          // Role label is optional; never fail the whole business context fetch.
          roleName = null;
        }
      }

      // Fetch first active branch for the business (default branch)
      // Note: Super Admin should NOT be assigned to any specific branch
      String? branchId;
      String? branchName;
      final isSuperAdmin =
          roleName?.trim().toLowerCase() == 'super admin' ||
          roleName?.trim().toLowerCase() == 'superadmin';

      if (businessId != null && !isSuperAdmin) {
        try {
          final branchRows = List<Map<String, dynamic>>.from(
            await client
                .from('branches')
                .select('id, name')
                .eq('business_id', businessId)
                .eq('is_active', true)
                .order('id', ascending: true)
                .limit(1),
          );
          if (branchRows.isNotEmpty) {
            branchId = branchRows.first['id']?.toString();
            branchName = branchRows.first['name']?.toString();
          } else {
            // Self-heal for older setups where the first branch was never created.
            final createdBranch = Map<String, dynamic>.from(
              await client
                  .from('branches')
                  .insert({
                    'id': const Uuid().v4(),
                    'business_id': businessId,
                    'name': 'Main Branch',
                    'is_active': true,
                  })
                  .select('id, name')
                  .single(),
            );

            branchId = createdBranch['id']?.toString();
            branchName = createdBranch['name']?.toString();

            // Best-effort: keep users.branch_id in sync with default branch.
            // Only for non-Super Admin users
            if ((branchId ?? '').isNotEmpty) {
              await client
                  .from('users')
                  .update({'branch_id': branchId})
                  .eq('id', current.id);
            }
          }
        } catch (_) {
          // Branch is optional, continue without it
          branchId = null;
          branchName = null;
        }
      }

      if (businessId == null && roleId == null && businessName == null) {
        return null;
      }

      return {
        'business_id': businessId,
        'role_id': roleId,
        'role_name': roleName,
        'business_name': businessName,
        'branch_id': branchId,
        'branch_name': branchName,
        'full_name': fullName,
        'template_id': templateId,
        'template_name': templateName,
      };
    } catch (_) {
      return null;
    }
  }
}
