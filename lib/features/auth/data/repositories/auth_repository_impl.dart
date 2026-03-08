import 'package:flutter/foundation.dart';
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
      // Have live session - load cached context from Drift for this user
      final cached = await _getCachedUserContextFor(liveUser.id);
      if (cached != null) {
        // Use cached context which includes businessId and other fields
        _cachedUserInMemory = cached;
        debugPrint(
          '💾 Loaded cached user context: businessId=${cached.businessId}, roleName=${cached.roleName}',
        );
      } else {
        // No cached context yet - use basic user from Supabase
        _cachedUserInMemory = AppUserModel.fromSupabaseUser(liveUser);
        debugPrint('📝 No cached context - using basic Supabase user');
      }
    } else {
      // No live session - try to load last cached user from Drift
      // This helps with offline cold starts
      // Note: For now we'll let it load on-demand in getCurrentUser()
      debugPrint('🔌 No live session at startup');
    }
  }

  @override
  AppUser? getCurrentUser() {
    final liveUser = remote.currentUser();
    if (liveUser == null) {
      // Fall back to in-memory cache when Supabase session is unavailable
      debugPrint(
        '🔌 No live session - using cached user (businessId: ${_cachedUserInMemory?.businessId})',
      );
      return _cachedUserInMemory;
    }

    final baseUser = AppUserModel.fromSupabaseUser(liveUser);

    // If we have cached context with business data, merge it with live user
    // This ensures businessId and other context is available immediately
    if (_cachedUserInMemory != null &&
        _cachedUserInMemory!.id == baseUser.id &&
        _cachedUserInMemory!.businessId != null) {
      debugPrint(
        '✅ Merging live user with cached context (businessId: ${_cachedUserInMemory!.businessId})',
      );
      return AppUserModel(
        id: baseUser.id,
        email: baseUser.email ?? _cachedUserInMemory!.email,
        fullName: baseUser.fullName ?? _cachedUserInMemory!.fullName,
        businessId: _cachedUserInMemory!.businessId,
        roleId: _cachedUserInMemory!.roleId,
        roleName: _cachedUserInMemory!.roleName,
        businessName: _cachedUserInMemory!.businessName,
        branchId: _cachedUserInMemory!.branchId,
        branchName: _cachedUserInMemory!.branchName,
      );
    }

    debugPrint('📝 Returning base user (no cached business context)');
    return baseUser;
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
  Future<void> sendPasswordResetOtp(String email) async {
    try {
      await remote.sendPasswordResetOtp(email);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    try {
      await remote.verifyPasswordResetOtp(email: email, token: token);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    try {
      await remote.updatePasswordAfterReset(newPassword);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<AppUser?> getUserBusinessContext(String userId) async {
    try {
      // Add timeout for network calls to prevent hanging
      final userData = await remote
          .getUserBusinessContext(userId)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              debugPrint(
                '⚠️ getUserBusinessContext timeout - using cached data',
              );
              return null;
            },
          );

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
