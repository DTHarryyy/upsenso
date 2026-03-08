import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/errors/supabase_error_mapper.dart';
import 'package:pos/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:pos/features/auth/data/models/app_user_model.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDs remote;
  final AuthContextDao authContextDao;
  final String oauthRedirectUrl;

  /// In-memory cache of current user context for fast offline access
  AppUser? _cachedUserInMemory;

  AuthRepositoryImpl(this.remote, this.authContextDao, this.oauthRedirectUrl);

  /// Initialize in-memory cache from Drift on app startup
  /// This ensures offline cold restart has access to cached business context
  Future<void> initializeCachedUser() async {
    final liveUser = remote.currentUser();
    if (liveUser != null) {
      // Prefer live session
      _cachedUserInMemory = AppUserModel.fromSupabaseUser(liveUser);
    } else {
      // Load from Drift cache if no live session (offline or session expired)
      // Need to get the last cached user (there should only be one per session)
      // For now, we'll let it be loaded on-demand when getCurrentUser() is called
      // This approach is lazy but safe
    }
  }

  @override
  AppUser? getCurrentUser() {
    final liveUser = remote.currentUser();
    if (liveUser == null) {
      // Fall back to in-memory cache when Supabase session is unavailable
      return _cachedUserInMemory;
    }

    return AppUserModel.fromSupabaseUser(liveUser);
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

    final appUser = AppUserModel.fromSupabaseUser(user);
    await _cacheUserContext(appUser);

    return appUser;
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await remote.signInWithGoogle(redirectTo: oauthRedirectUrl);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<void> signInWithFacebook() async {
    try {
      await remote.signInWithFacebook(redirectTo: oauthRedirectUrl);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<AppUser> signUp(String email, String password) async {
    try {
      final res = await remote.signUp(email, password);

      final user = res.user;
      if (user == null) {
        return throw 'Account created. Please check your email to confirm.';
      }

      final appUser = AppUserModel.fromSupabaseUser(user);
      await _cacheUserContext(appUser);

      return appUser;
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

      final appUser = AppUserModel.fromSupabaseUser(freshUser);
      await _cacheUserContext(appUser);

      return appUser;
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<void> signOut() async {
    _cachedUserInMemory = null;
    final currentUser = getCurrentUser();
    if (currentUser != null) {
      await authContextDao.clearContext(currentUser.id);
    }
    await remote.signOut();
  }

  @override
  Future<AppUser?> getUserBusinessContext(String userId) async {
    try {
      final userData = await remote.getUserBusinessContext(userId);

      // Always try to get existing cached context first
      final currentUser = getCurrentUser();
      final cachedUser = await _getCachedUserContextFor(userId);
      final baseUser = currentUser != null && currentUser.id == userId
          ? currentUser
          : cachedUser;

      if (userData == null) {
        // No remote data - return cached context if it has business data
        if (cachedUser != null && cachedUser.businessId != null) {
          return cachedUser;
        }
        return baseUser;
      }

      final user = AppUserModel(
        id: userId,
        email: baseUser?.email,
        fullName:
            _normalizeNullableString(userData['full_name']) ??
            baseUser?.fullName,
        businessId:
            _normalizeNullableString(userData['business_id']) ??
            baseUser?.businessId,
        roleId:
            _normalizeNullableString(userData['role_id']) ?? baseUser?.roleId,
        roleName:
            _normalizeNullableString(userData['role_name']) ??
            baseUser?.roleName,
        businessName:
            _normalizeNullableString(userData['business_name']) ??
            baseUser?.businessName,
        branchId:
            _normalizeNullableString(userData['branch_id']) ??
            baseUser?.branchId,
        branchName:
            _normalizeNullableString(userData['branch_name']) ??
            baseUser?.branchName,
      );

      // Cache the user context for offline use
      await _cacheUserContext(user);

      return user;
    } catch (e) {
      // When offline or remote fails, return cached context
      final cached = await _getCachedUserContextFor(userId);
      if (cached != null) {
        return cached;
      }

      // Last resort: return current user even without business context
      return getCurrentUser();
    }
  }

  /// Cache user business context in both in-memory cache and Drift for offline access
  Future<void> _cacheUserContext(AppUser user) async {
    // Update in-memory cache for fast sync access
    _cachedUserInMemory = AppUserModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      businessId: user.businessId,
      roleId: user.roleId,
      roleName: user.roleName,
      businessName: user.businessName,
      branchId: user.branchId,
      branchName: user.branchName,
    );

    // Persist to Drift for app restart recovery
    await authContextDao.saveContext(
      userId: user.id,
      email: user.email,
      fullName: user.fullName,
      businessId: user.businessId,
      roleId: user.roleId,
      roleName: user.roleName,
      businessName: user.businessName,
      branchId: user.branchId,
      branchName: user.branchName,
    );
  }

  /// Retrieve cached user context from Drift when offline
  /// Also updates in-memory cache so getCurrentUser() returns fresh data
  Future<AppUser?> _getCachedUserContextFor(String userId) async {
    final cached = await authContextDao.getContext(userId);
    if (cached != null) {
      final entity = AuthContextDao.toEntity(cached);
      // Sync in-memory cache with Drift cache so getCurrentUser() is up-to-date
      _cachedUserInMemory = entity;
      return entity;
    }
    return null;
  }

  String? _normalizeNullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}
