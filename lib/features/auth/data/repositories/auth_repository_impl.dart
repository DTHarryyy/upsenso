import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

  AppUser? _cachedUserInMemory;

  AuthRepositoryImpl(this.remote, this.authContextDao, this.oauthRedirectUrl);

  Future<void> initializeCachedUser() async {
    final liveUser = remote.currentUser();
    if (liveUser != null) {
      final cached = await _getCachedUserContextFor(liveUser.id);
      if (cached != null) {
        _cachedUserInMemory = cached;
      } else {
        _cachedUserInMemory = AppUserModel.fromSupabaseUser(liveUser);
      }
    }
  }

  @override
  AppUser? getCurrentUser() {
    final liveUser = remote.currentUser();
    if (liveUser == null) {
      return _cachedUserInMemory;
    }

    final baseUser = AppUserModel.fromSupabaseUser(liveUser);

    // If we have cached context with business data, merge it with live user
    // This ensures businessId and other context is available immediately
    if (_cachedUserInMemory != null &&
        _cachedUserInMemory!.id == baseUser.id &&
        _cachedUserInMemory!.businessId != null) {
      return AppUserModel(
        id: baseUser.id,
        email: baseUser.email ?? _cachedUserInMemory!.email,
        fullName: baseUser.fullName ?? _cachedUserInMemory!.fullName,
        avatarUrl: _cachedUserInMemory!.avatarUrl ?? baseUser.avatarUrl,
        businessId: _cachedUserInMemory!.businessId,
        roleId: _cachedUserInMemory!.roleId,
        roleName: _cachedUserInMemory!.roleName,
        businessName: _cachedUserInMemory!.businessName,
        branchId: _cachedUserInMemory!.branchId,
        branchName: _cachedUserInMemory!.branchName,
        businessTemplateId: _cachedUserInMemory!.businessTemplateId,
        businessTemplateName: _cachedUserInMemory!.businessTemplateName,
      );
    }

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

    // Load existing Drift cache first so we can use the profile-set name below.
    final existing = await _getCachedUserContextFor(user.id);
    final existingBusinessId = existing?.businessId;

    // Ensure user has full_name set. Prefer the Drift-cached profile name so
    // that Supabase metadata stays in sync with what the user set in-app.
    // Falls back to email-derived name only when there is no cached name.
    if (user.userMetadata?['full_name'] == null ||
        user.userMetadata?['full_name'] == '') {
      await remote.updateUserMetadata(
        email: email,
        fullName: existing?.fullName,
      );
    }

    final appUser = AppUserModel.fromSupabaseUser(user);

    // Preserve any businessId/role context from a previous session so that a
    // slow or failing getUserBusinessContext fetch doesn't strip the context
    // and send an existing user to businessProfileSetup.
    if (existing != null && existingBusinessId != null) {
      _cachedUserInMemory = AppUserModel(
        id: appUser.id,
        email: appUser.email ?? existing.email,
        // Prefer Drift-cached fullName (set by profile edits) over the
        // session metadata value which may be an email-derived fallback.
        fullName: existing.fullName ?? appUser.fullName,
        avatarUrl: existing.avatarUrl ?? appUser.avatarUrl,
        businessId: existing.businessId,
        roleId: existing.roleId,
        roleName: existing.roleName,
        businessName: existing.businessName,
        branchId: existing.branchId,
        branchName: existing.branchName,
        businessTemplateId: existing.businessTemplateId,
        businessTemplateName: existing.businessTemplateName,
      );
      // DB already has the correct context — no overwrite needed.
    } else {
      await _cacheUserContext(appUser);
    }

    return appUser;
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await remote.signInWithGoogle(mobileRedirectTo: oauthRedirectUrl);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<void> signInWithFacebook() async {
    try {
      await remote.signInWithFacebook(mobileRedirectTo: oauthRedirectUrl);
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
    // Clear only the in-memory cache. Keeping the DB auth context lets the
    // same user re-login and immediately get their businessId from cache,
    // avoiding the race where a slow getUserBusinessContext fetch returns a
    // partial user that sends them back to businessProfileSetup.
    // The cache is keyed by userId, so different users on the same device
    // never see each other's records.
    _cachedUserInMemory = null;
    // Best-effort remote sign-out: local session is already cleared above,
    // so an offline failure should not prevent the user from being signed out.
    try {
      await remote.signOut();
    } catch (_) {}
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
            const Duration(seconds: 2),
            onTimeout: () {
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
        // Prefer the cached/session fullName (updated by profile edits via
        // updateUserMetadata) over the DB function's potentially stale value.
        fullName:
            baseUser?.fullName ??
            _normalizeNullableString(userData['full_name']),
        avatarUrl: _cachedUserInMemory?.avatarUrl ?? baseUser?.avatarUrl,
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
        businessTemplateId:
            _normalizeNullableString(userData['template_id']) ??
            baseUser?.businessTemplateId,
        businessTemplateName:
            _normalizeNullableString(userData['template_name']) ??
            baseUser?.businessTemplateName,
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
      avatarUrl: user.avatarUrl,
      businessId: user.businessId,
      roleId: user.roleId,
      roleName: user.roleName,
      businessName: user.businessName,
      branchId: user.branchId,
      branchName: user.branchName,
      businessTemplateId: user.businessTemplateId,
      businessTemplateName: user.businessTemplateName,
    );

    // Persist to Drift for app restart recovery
    await authContextDao.saveContext(
      userId: user.id,
      email: user.email,
      fullName: user.fullName,
      avatarUrl: user.avatarUrl,
      businessId: user.businessId,
      roleId: user.roleId,
      roleName: user.roleName,
      businessName: user.businessName,
      branchId: user.branchId,
      branchName: user.branchName,
      businessTemplateId: user.businessTemplateId,
      businessTemplateName: user.businessTemplateName,
    );

    // Keep exactly one cached context — the active user. This neutralises the
    // tenant-agnostic getAny() lookup so it can never return a previous
    // account's business on a shared device.
    await authContextDao.deleteOthers(user.id);
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

  @override
  Future<AppUser> uploadAvatar(String userId, List<int> bytes) async {
    final current = _cachedUserInMemory;

    if (kIsWeb) {
      // Web has no local filesystem — upload directly and await the result.
      final remoteUrl = await remote.uploadAvatar(bytes, userId);
      await remote.updateAvatarUrl(userId, remoteUrl);
      final updated = AppUserModel(
        id: userId,
        email: current?.email,
        fullName: current?.fullName,
        avatarUrl: remoteUrl,
        businessId: current?.businessId,
        roleId: current?.roleId,
        roleName: current?.roleName,
        businessName: current?.businessName,
        branchId: current?.branchId,
        branchName: current?.branchName,
        businessTemplateId: current?.businessTemplateId,
        businessTemplateName: current?.businessTemplateName,
      );
      await _cacheUserContext(updated);
      return updated;
    }

    // Native: save locally first so the UI updates instantly without network.
    final dir = await getApplicationDocumentsDirectory();
    final localPath = p.join(dir.path, '${userId}_avatar.jpg');
    await File(localPath).writeAsBytes(bytes, flush: true);

    final localUser = AppUserModel(
      id: userId,
      email: current?.email,
      fullName: current?.fullName,
      avatarUrl: localPath,
      businessId: current?.businessId,
      roleId: current?.roleId,
      roleName: current?.roleName,
      businessName: current?.businessName,
      branchId: current?.branchId,
      branchName: current?.branchName,
      businessTemplateId: current?.businessTemplateId,
      businessTemplateName: current?.businessTemplateName,
    );
    await _cacheUserContext(localUser);

    // Background sync to Supabase — does not block the caller.
    unawaited(
      _syncAvatarToRemote(userId, bytes, localPath).catchError((e) {
        debugPrint('AuthRepo: background avatar sync failed: $e');
      }),
    );

    return localUser;
  }

  Future<void> _syncAvatarToRemote(
    String userId,
    List<int> bytes,
    String localPath,
  ) async {
    final remoteUrl = await remote.uploadAvatar(bytes, userId);
    await remote.updateAvatarUrl(userId, remoteUrl);

    final current = _cachedUserInMemory;
    // Only update if the user hasn't picked a newer avatar since.
    if (current?.avatarUrl == localPath) {
      final updated = AppUserModel(
        id: userId,
        email: current?.email,
        fullName: current?.fullName,
        avatarUrl: remoteUrl,
        businessId: current?.businessId,
        roleId: current?.roleId,
        roleName: current?.roleName,
        businessName: current?.businessName,
        branchId: current?.branchId,
        branchName: current?.branchName,
        businessTemplateId: current?.businessTemplateId,
        businessTemplateName: current?.businessTemplateName,
      );
      await _cacheUserContext(updated);
    }
  }

  @override
  Future<void> changePassword(String newPassword) async {
    try {
      await remote.updatePassword(newPassword);
    } catch (e) {
      throw SupabaseAuthErrorMapper.message(e);
    }
  }

  @override
  Future<AppUser> updateProfile({required String fullName}) async {
    final current = _cachedUserInMemory;
    final email = current?.email ?? remote.currentUser()?.email ?? '';
    await remote.updateUserMetadata(email: email, fullName: fullName);
    final updated = AppUserModel(
      id: current?.id ?? remote.currentUser()!.id,
      email: current?.email,
      fullName: fullName,
      avatarUrl: current?.avatarUrl,
      businessId: current?.businessId,
      roleId: current?.roleId,
      roleName: current?.roleName,
      businessName: current?.businessName,
      branchId: current?.branchId,
      branchName: current?.branchName,
      businessTemplateId: current?.businessTemplateId,
      businessTemplateName: current?.businessTemplateName,
    );
    await _cacheUserContext(updated);
    return updated;
  }

  String? _normalizeNullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}
