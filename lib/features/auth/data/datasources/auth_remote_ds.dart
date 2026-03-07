import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDs {
  final SupabaseClient client;
  AuthRemoteDs(this.client);

  User? currentUser() => client.auth.currentUser;

  Stream<AuthState> onAuthStateChange() => client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
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

  /// Extract name from email (part before @)
  String _extractNameFromEmail(String email) {
    final username = email.split('@')[0];
    // Convert to title case (e.g., "john.doe" -> "John Doe")
    return username
        .split(RegExp(r'[._-]'))
        .map(
          (part) => part.isEmpty
              ? ''
              : part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Future<void> signOut() => client.auth.signOut();

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
        'business_name': row['business_name']?.toString(),
        'full_name': fullName,
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
      final currentEmail = current?.email;

      Map<String, dynamic>? userRow;
      Map<String, dynamic>? businessRow;

      final userByIdRows = List<Map<String, dynamic>>.from(
        await client.from('users').select().eq('id', userId).limit(1),
      );
      if (userByIdRows.isNotEmpty) {
        userRow = userByIdRows.first;
      }

      if (userRow == null && (currentEmail ?? '').isNotEmpty) {
        final userByEmailRows = List<Map<String, dynamic>>.from(
          await client
              .from('users')
              .select()
              .eq('email', currentEmail!)
              .limit(1),
        );
        if (userByEmailRows.isNotEmpty) {
          userRow = userByEmailRows.first;
        }
      }

      String? businessId = userRow?['business_id']?.toString();
      String? roleId = userRow?['role_id']?.toString();
      final fullName =
          userRow?['full_name']?.toString() ??
          userRow?['fu l_name']?.toString();

      if (businessId != null) {
        final businessByIdRows = List<Map<String, dynamic>>.from(
          await client
              .from('businesses')
              .select('id, name')
              .eq('id', businessId)
              .limit(1),
        );

        if (businessByIdRows.isNotEmpty) {
          businessRow = businessByIdRows.first;
        }
      }

      if (businessRow == null && current != null) {
        final businessByOwnerRows = List<Map<String, dynamic>>.from(
          await client
              .from('businesses')
              .select('id, name')
              .eq('owner_id', current.id)
              .order('created_at', ascending: false)
              .limit(1),
        );

        if (businessByOwnerRows.isNotEmpty) {
          businessRow = businessByOwnerRows.first;
          businessId ??= businessRow['id']?.toString();
        }
      }

      // Fallback: derive role by matching business + email.
      if (roleId == null &&
          businessId != null &&
          (currentEmail ?? '').isNotEmpty) {
        final roleByBusinessRows = List<Map<String, dynamic>>.from(
          await client
              .from('users')
              .select('role_id')
              .eq('business_id', businessId)
              .eq('email', currentEmail!)
              .limit(1),
        );

        if (roleByBusinessRows.isNotEmpty) {
          roleId = roleByBusinessRows.first['role_id']?.toString();
        }
      }

      // Final fallback: owner is typically Super Admin for created business.
      if (roleId == null && businessId != null) {
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

      if (businessId == null && roleId == null && businessName == null) {
        return null;
      }

      return {
        'business_id': businessId,
        'role_id': roleId,
        'business_name': businessName,
        'full_name': fullName,
      };
    } catch (_) {
      return null;
    }
  }
}
