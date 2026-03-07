import 'package:pos/core/errors/supabase_error_mapper.dart';
import 'package:pos/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:pos/features/auth/data/models/app_user_model.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDs remote;
  final SharedPreferences prefs;

  static const _keyBusinessId = 'cached_business_id';
  static const _keyBusinessName = 'cached_business_name';
  static const _keyRoleId = 'cached_role_id';
  static const _keyFullName = 'cached_full_name';

  AuthRepositoryImpl(this.remote, this.prefs);

  @override
  AppUser? getCurrentUser() {
    final user = remote.currentUser();
    return user == null ? null : AppUserModel.fromSupabaseUser(user);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return remote.onAuthStateChange().map((state) {
      final user = state.session?.user;
      return user == null ? null : AppUserModel.fromSupabaseUser(user);
    });
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final res = await remote.signIn(email, password);
    final user = res.user;
    if (user == null) throw Exception('Sign-in failed (no user).');

    // Ensure user has full_name set from email if missing
    if (user.userMetadata?['full_name'] == null ||
        user.userMetadata?['full_name'] == '') {
      await remote.updateUserMetadata(email: email);
    }

    return AppUserModel.fromSupabaseUser(user);
  }

  @override
  Future<AppUser> signUp(String email, String password) async {
    try {
      final res = await remote.signUp(email, password);

      final user = res.user;
      if (user == null) {
        return throw 'Account created. Please check your email to confirm.';
      }

      return AppUserModel.fromSupabaseUser(user);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    try {
      return await remote.checkEmailExists(email);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<void> sendSignUpOtp(String email) async {
    try {
      await remote.sendSignUpOtp(email);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<AppUser> verifySignUpOtp({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      final verifyRes = await remote.verifyEmailOtp(email: email, token: token);
      final verifiedUser = verifyRes.user;

      if (verifiedUser == null) {
        throw 'Verification failed. Please request a new code and try again.';
      }

      await remote.updatePassword(password);

      // Set default full name from email in user
      await remote.updateUserMetadata(email: email);

      final freshUser = remote.currentUser();
      if (freshUser == null) {
        throw 'Verification succeeded, but user session was not found.';
      }

      return AppUserModel.fromSupabaseUser(freshUser);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<void> signOut() => remote.signOut();

  @override
  Future<AppUser?> getUserBusinessContext(String userId) async {
    try {
      final userData = await remote.getUserBusinessContext(userId);
      if (userData == null) {
        return _getCachedUserContext();
      }

      final currentUser = getCurrentUser();
      if (currentUser == null) return _getCachedUserContext();

      final user = AppUserModel(
        id: currentUser.id,
        email: currentUser.email,
        fullName: (userData['full_name'] as String?)?.trim().isNotEmpty == true
            ? userData['full_name'] as String?
            : currentUser.fullName,
        businessId: userData['business_id'] as String?,
        roleId: userData['role_id'] as String?,
        businessName: userData['business_name'] as String?,
      );

      // Cache the user context for offline use
      await _cacheUserContext(user);

      return user;
    } catch (_) {
      // When offline or remote fails, return cached context
      return _getCachedUserContext();
    }
  }

  /// Cache user business context locally for offline access
  Future<void> _cacheUserContext(AppUser user) async {
    await prefs.setString(_keyBusinessId, user.businessId ?? '');
    await prefs.setString(_keyBusinessName, user.businessName ?? '');
    await prefs.setString(_keyRoleId, user.roleId ?? '');
    await prefs.setString(_keyFullName, user.fullName ?? '');
  }

  /// Retrieve cached user context when offline
  AppUser? _getCachedUserContext() {
    final currentUser = getCurrentUser();
    if (currentUser == null) return null;

    final cachedBusinessId = prefs.getString(_keyBusinessId);
    final cachedBusinessName = prefs.getString(_keyBusinessName);
    final cachedRoleId = prefs.getString(_keyRoleId);
    final cachedFullName = prefs.getString(_keyFullName);

    // Return cached data if available
    if (cachedBusinessId != null && cachedBusinessId.isNotEmpty) {
      return AppUserModel(
        id: currentUser.id,
        email: currentUser.email,
        fullName: cachedFullName?.isNotEmpty == true
            ? cachedFullName
            : currentUser.fullName,
        businessId: cachedBusinessId,
        roleId: cachedRoleId,
        businessName: cachedBusinessName,
      );
    }

    return null;
  }
}
