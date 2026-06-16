import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/errors/supabase_error_mapper.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';

import '../../domain/usecases/check_email_exists.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/get_user_business_context.dart';
import '../../domain/usecases/observe_auth_state.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/send_password_reset_otp.dart';
import '../../domain/usecases/send_sign_up_otp.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_in_with_facebook.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/verify_password_reset_otp.dart';
import '../../domain/usecases/verify_sign_up_otp.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser getCurrentUser;
  final GetUserBusinessContext getUserBusinessContext;
  final ObserveAuthState observeAuthState;
  final SignIn signIn;
  final SignInWithGoogle signInWithGoogle;
  final SignInWithFacebook signInWithFacebook;
  final CheckEmailExists checkEmailExists;
  final SendSignUpOtp sendSignUpOtp;
  final VerifySignUpOtp verifySignUpOtp;
  final SignOut signOut;
  final SendPasswordResetOtp sendPasswordResetOtp;
  final VerifyPasswordResetOtp verifyPasswordResetOtp;
  final ResetPassword resetPassword;
  final ConnectivityService connectivityService;
  final SyncService? syncService;

  StreamSubscription? _sub;
  String? _pendingSignUpEmail;
  String? _pendingSignUpPassword;
  String? _pendingResetEmail;

  String _errorMessage(Object err) {
    if (err is String) return err;
    return SupabaseAuthErrorMapper.message(err);
  }

  /// Blocking full pull — awaited on fresh login/signup so the home screen
  /// opens with all data already in the local DB.
  Future<void> _initialSync(AppUser user) async {
    final id = user.businessId;
    if (id == null || id.trim().isEmpty) return;
    await syncService?.syncAll(businessId: id);
  }

  /// Fire-and-forget pull — used on app restart where cached data is already
  /// present and we don't want to block the UI.
  void _backgroundSync(AppUser user) {
    final id = user.businessId;
    if (id == null || id.trim().isEmpty) return;
    unawaited(syncService?.syncAll(businessId: id));
  }

  // ── Active-tenant helpers ─────────────────────────────────────────────────

  /// Bind the authoritative active session. Every tenant-sensitive service
  /// (sync, audit, permissions) resolves businessId from here, so this MUST be
  /// set before emitting [AuthAuthenticated].
  void _setActiveContext(AppUser user) {
    sl<ActiveBusinessContext>().set(
      userId: user.id,
      businessId: user.businessId,
      branchId: user.branchId,
      branchName: user.branchName,
      roleName: user.roleName,
      fullName: user.fullName,
    );
  }

  /// Set the active context, then emit [AuthAuthenticated]. Single choke point
  /// so the in-memory tenant can never lag behind the emitted auth state.
  void _emitAuthenticated(Emitter<AuthState> emit, AppUser user) {
    _setActiveContext(user);
    emit(AuthAuthenticated(user));
  }

  /// The userId cached on this device BEFORE the current authentication began.
  /// Captured before any sign-in/context fetch (which rewrites the cache), so we
  /// can reliably tell a re-login from an account switch.
  Future<String?> _priorCachedUserId() async {
    final ctx = await sl<AuthContextDao>().getAny();
    return ctx?.userId;
  }

  /// When a DIFFERENT account is authenticating on this device, wipe all local
  /// business data + cached context so the new account can never inherit the
  /// previous tenant's records. [priorUserId] must be captured BEFORE sign-in.
  /// No-op for a fresh device or the same user re-logging in.
  Future<void> _resetIfAccountSwitch(
    String? priorUserId,
    String newUserId,
  ) async {
    if (priorUserId == null || priorUserId == newUserId) return;
    debugPrint('[AuthBloc] Account switch detected — clearing local data');
    sl<PermissionService>().clearPermissions();
    sl<ActiveBusinessContext>().clear();
    await syncService?.clearLocalData();
  }

  // ── Permission helpers ────────────────────────────────────────────────────

  /// Sets the in-memory role/branch/user context on [PermissionService].
  void _applyPermissionContext(AppUser user) {
    sl<PermissionService>().setContext(
      roleName: user.roleName,
      branchId: user.branchId,
      userId: user.id,
    );
  }

  /// Sets context + loads permissions and module state from the local Drift
  /// cache.  Fast — no network I/O.  Call before emitting [AuthAuthenticated].
  Future<void> _loadPermissionsFromCache(AppUser user) async {
    _applyPermissionContext(user);
    await sl<PermissionService>().loadPermissions(user.id);
    final bid = user.businessId;
    if (bid != null && bid.isNotEmpty) {
      await sl<PermissionService>().loadEnabledModules(bid);
    }
  }

  /// Fire-and-forget Supabase sync for both permissions and module state.
  void _syncPermissionsBackground(AppUser user) {
    unawaited(sl<PermissionService>().syncPermissions(user.id));
    final bid = user.businessId;
    if (bid != null && bid.isNotEmpty) {
      unawaited(sl<PermissionService>().syncModules(bid));
    }
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  bool _hasRoleContext(AppUser user) {
    return _hasText(user.roleId) || _hasText(user.roleName);
  }

  bool _hasCompleteContext(AppUser? user) {
    if (user == null) return false;
    return _hasText(user.businessId) && _hasRoleContext(user);
  }

  bool _sameContext(AppUser a, AppUser b) {
    return a.id == b.id &&
        a.fullName == b.fullName &&
        a.avatarUrl == b.avatarUrl &&
        a.businessId == b.businessId &&
        a.roleId == b.roleId &&
        a.roleName == b.roleName &&
        a.businessName == b.businessName &&
        a.branchId == b.branchId &&
        a.branchName == b.branchName &&
        a.businessTemplateName == b.businessTemplateName;
  }

  Future<AppUser?> _getUserContextWithRetry(String userId) async {
    // If we already have a complete cached context, avoid extra remote calls.
    final current = getCurrentUser();
    if (current != null &&
        current.id == userId &&
        _hasCompleteContext(current)) {
      return current;
    }

    final isOnline = await connectivityService.isConnected;

    if (!isOnline) {
      final cachedUser = await getUserBusinessContext(userId);
      return cachedUser;
    }

    AppUser? latest;
    for (var attempt = 0; attempt < 2; attempt++) {
      final userWithContext = await getUserBusinessContext(userId);
      latest = userWithContext;

      if (userWithContext != null) {
        final hasBusiness = _hasText(userWithContext.businessId);
        final hasRole =
            _hasText(userWithContext.roleId) ||
            _hasText(userWithContext.roleName);

        if (!hasBusiness) {
          return userWithContext;
        }

        if (hasRole) {
          return userWithContext;
        }
      }

      if (attempt < 1) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    return latest ?? await getUserBusinessContext(userId);
  }

  AuthBloc({
    required this.getCurrentUser,
    required this.getUserBusinessContext,
    required this.observeAuthState,
    required this.signIn,
    required this.signInWithGoogle,
    required this.signInWithFacebook,
    required this.checkEmailExists,
    required this.sendSignUpOtp,
    required this.verifySignUpOtp,
    required this.signOut,
    required this.sendPasswordResetOtp,
    required this.verifyPasswordResetOtp,
    required this.resetPassword,
    required this.connectivityService,
    this.syncService,
  }) : super(AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthUserContextUpdated>(_onUserContextUpdated);
    on<AuthLoginRequested>(_onLogin);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthFacebookSignInRequested>(_onFacebookSignIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthVerifySignUpCodeRequested>(_onVerifySignUpCode);
    on<AuthResendSignUpCodeRequested>(_onResendSignUpCode);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthVerifyResetCodeRequested>(_onVerifyResetCode);
    on<AuthResetPasswordRequested>(_onResetPassword);
    on<AuthResendResetCodeRequested>(_onResendResetCode);

    _sub = observeAuthState().listen((user) {
      add(AuthUserChanged(user != null));
    });
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    var user = getCurrentUser();

    if (user == null) {
      emit(AuthUnauthenticated());
      return;
    }

    // Fast path: cached context is already complete — emit immediately and
    // kick off a background sync without blocking the UI.
    if (_hasCompleteContext(user)) {
      debugPrint('AuthBloc: Emitting cached user (with complete context)');
      await _loadPermissionsFromCache(user);
      _emitAuthenticated(emit, user);
      _backgroundSync(user);
      _syncPermissionsBackground(user);
      return;
    }

    // Slow path: context is incomplete (e.g. fresh WASM DB, OAuth redirect
    // before IndexedDB was written, or first-ever login on this device).
    // Fetch from remote/cache with a hard cap so we never block startup
    // indefinitely. Emitting before the fetch would cause the router to
    // redirect to /business-profile-setup for existing users.
    debugPrint('AuthBloc: Context incomplete — fetching before emitting');
    try {
      final resolved = await _getUserContextWithRetry(user.id).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint(
            'AuthBloc: Context fetch timed out — emitting partial user',
          );
          return null;
        },
      );
      final authed = resolved ?? user;
      debugPrint(
        'AuthBloc: Emitting resolved user '
        '(${authed.businessId != null ? "with" : "without"} business)',
      );
      await _loadPermissionsFromCache(authed);
      _emitAuthenticated(emit, authed);
      _backgroundSync(authed);
      _syncPermissionsBackground(authed);
    } catch (e) {
      debugPrint('AuthBloc: Context fetch failed: $e — emitting partial user');
      await _loadPermissionsFromCache(user);
      _emitAuthenticated(emit, user);
      _backgroundSync(user);
      _syncPermissionsBackground(user);
    }
  }

  Future<void> _onUserContextUpdated(
    AuthUserContextUpdated event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthAuthenticated &&
        _sameContext(currentState.user, event.user)) {
      return;
    }
    _emitAuthenticated(emit, event.user);
  }

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading(type: AuthLoadingType.email));
    try {
      final priorUserId = await _priorCachedUserId();
      final user = await signIn(e.email, e.password);
      // Wipe any previous account's local data BEFORE pulling this account's.
      await _resetIfAccountSwitch(priorUserId, user.id);
      final authed = (await _getUserContextWithRetry(user.id)) ?? user;
      await _initialSync(authed);
      await _loadPermissionsFromCache(authed);
      _emitAuthenticated(emit, authed);
      _syncPermissionsBackground(authed);
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.userLogin,
        entityType: 'user',
        entityId: authed.id,
        entityName: authed.fullName,
        userName: authed.fullName,
        description:
            'User signed in: ${authed.fullName ?? authed.email ?? 'user'}',
        metadata: {
          'method': 'email',
          'role': authed.roleName ?? 'Unknown',
          'branch': authed.branchName?.isNotEmpty == true
              ? authed.branchName!
              : 'All Branches',
        },
        businessId: authed.businessId ?? '',
        branchId: authed.branchId ?? '',
        userId: authed.id,
      );
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(type: AuthLoadingType.google));
    try {
      await signInWithGoogle();
      emit(const AuthOAuthInProgress('google'));
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onFacebookSignIn(
    AuthFacebookSignInRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(type: AuthLoadingType.facebook));
    try {
      await signInWithFacebook();
      emit(const AuthOAuthInProgress('facebook'));
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(type: AuthLoadingType.signUp));
    try {
      final emailExists = await checkEmailExists(e.email);
      if (emailExists) {
        throw 'This email is already registered. Try signing in instead.';
      }

      await sendSignUpOtp(e.email);
      _pendingSignUpEmail = e.email;
      _pendingSignUpPassword = e.password;
      emit(AuthCodeSent(e.email));
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onVerifySignUpCode(
    AuthVerifySignUpCodeRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(type: AuthLoadingType.verifyCode));
    try {
      final pendingEmail = _pendingSignUpEmail;
      final pendingPassword = _pendingSignUpPassword;

      if (pendingEmail == null || pendingPassword == null) {
        throw 'Sign up session expired. Please start again.';
      }

      if (pendingEmail != e.email) {
        throw 'Verification email mismatch. Please start sign up again.';
      }

      final priorUserId = await _priorCachedUserId();
      final user = await verifySignUpOtp(
        email: e.email,
        token: e.code,
        password: pendingPassword,
      );

      _pendingSignUpEmail = null;
      _pendingSignUpPassword = null;

      // A brand-new account on a device that still holds a previous account's
      // data: wipe it before establishing the new context.
      await _resetIfAccountSwitch(priorUserId, user.id);
      final authed = (await _getUserContextWithRetry(user.id)) ?? user;
      await _initialSync(authed);
      await _loadPermissionsFromCache(authed);
      _emitAuthenticated(emit, authed);
      _syncPermissionsBackground(authed);
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
    }
  }

  Future<void> _onResendSignUpCode(
    AuthResendSignUpCodeRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(type: AuthLoadingType.signUp));
    try {
      await sendSignUpOtp(e.email);
      _pendingSignUpEmail = e.email;
      emit(AuthCodeSent(e.email));
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    _pendingSignUpEmail = null;
    _pendingSignUpPassword = null;

    // Log before clearing local data so the context is still available.
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      await sl<AuditLogService>().log(
        actionType: AuditLogActionType.userLogout,
        entityType: 'user',
        entityId: currentState.user.id,
        entityName: currentState.user.fullName,
        userName: currentState.user.fullName,
        description:
            'User signed out: ${currentState.user.fullName ?? currentState.user.email ?? 'user'}',
        metadata: {
          'role': currentState.user.roleName ?? 'Unknown',
          'branch': currentState.user.branchName?.isNotEmpty == true
              ? currentState.user.branchName!
              : 'All Branches',
        },
        businessId: currentState.user.businessId ?? '',
        branchId: currentState.user.branchId ?? '',
        userId: currentState.user.id,
      );
    }

    // Push everything pending to the server BEFORE wiping local data — a
    // logout must never destroy unsynced sales/inventory. If anything is still
    // unsynced afterwards (offline, or sync failed), keep the local data and
    // skip the destructive wipe; it will sync on the next session instead.
    sl<PermissionService>().clearPermissions();
    if (syncService != null) {
      final businessId = currentState is AuthAuthenticated
          ? currentState.user.businessId
          : null;
      if (await syncService!.isOnline) {
        await syncService!.syncAll(businessId: businessId);
      }
      final pending = await syncService!.pendingSyncCount();
      if (pending == 0) {
        await syncService!.clearLocalData();
      } else {
        debugPrint(
          '[AuthBloc] Logout: $pending unsynced record(s) remain — '
          'skipping local wipe to avoid data loss',
        );
      }
      // Stop background sync triggers so no timer-/connectivity-driven pull
      // runs while logged out. If the wipe above was skipped (unsynced data),
      // the next DIFFERENT account login wipes it via _resetIfAccountSwitch
      // before pulling, so a new account never inherits this tenant's data.
      syncService!.pause();
    }

    // Drop the authoritative active tenant — guards every getAny-free resolver.
    sl<ActiveBusinessContext>().clear();

    emit(AuthUnauthenticated());

    unawaited(
      signOut().catchError((err) {
        debugPrint('AuthBloc: sign-out server call failed: $err');
      }),
    );
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (!event.isLoggedIn) {
      // If we were authenticated when the sign-out arrived, this was not
      // triggered by our explicit logout flow (which emits AuthUnauthenticated
      // before calling signOut()). Treat it as a forced/expired session.
      if (state is AuthAuthenticated) {
        emit(
          const AuthError('Your session has expired. Please sign in again.'),
        );
      }
      sl<ActiveBusinessContext>().clear();
      syncService?.pause();
      emit(AuthUnauthenticated());
      return;
    }

    final user = getCurrentUser();
    if (user == null) {
      sl<ActiveBusinessContext>().clear();
      emit(AuthUnauthenticated());
      return;
    }

    final currentState = state;
    if (currentState is AuthAuthenticated && currentState.user.id == user.id) {
      // Ignore noisy auth stream events when nothing meaningful changed.
      if (_sameContext(currentState.user, user)) {
        return;
      }

      // Keep richer state if incoming auth user has less context during network issues.
      if (_hasCompleteContext(currentState.user) &&
          !_hasCompleteContext(user)) {
        return;
      }
    }

    // OAuth/external account switch: if a different account's data is still on
    // this device, wipe it before establishing the new context. (Capture the
    // prior id before getUserBusinessContext rewrites the cache.)
    final priorUserId = await _priorCachedUserId();
    await _resetIfAccountSwitch(priorUserId, user.id);

    // Avoid extra network fetches when current user already has complete context.
    if (_hasCompleteContext(user)) {
      await _loadPermissionsFromCache(user);
      _emitAuthenticated(emit, user);
      return;
    }

    // Before doing any async work, eagerly emit whatever cached context is
    // already available. This prevents the router from redirecting to
    // /business-profile-setup during the brief window between an OAuth
    // redirect (where the Supabase session is fresh but businessId hasn't
    // been fetched yet) and the getUserBusinessContext call completing.
    final cachedContext = await getUserBusinessContext(
      user.id,
    ).timeout(const Duration(seconds: 3), onTimeout: () => null);
    if (cachedContext != null && _hasCompleteContext(cachedContext)) {
      _emitAuthenticated(emit, cachedContext);
      return;
    }

    // Emit what we have so far (may have businessId from cache even without role).
    // This ensures hasBusiness is true in the router so setup is not triggered.
    final interim = cachedContext ?? user;
    if (_hasText(interim.businessId)) {
      _emitAuthenticated(emit, interim);
    }

    final userWithContext = await _getUserContextWithRetry(
      user.id,
    ).timeout(const Duration(seconds: 5), onTimeout: () => interim);
    final resolved = userWithContext ?? interim;

    // Never downgrade: if we already have a complete context (businessId +
    // role) in the current state but the freshly-fetched user is missing it
    // (e.g. network hiccup during token refresh), keep the richer state.
    final stateAfterFetch = state;
    if (stateAfterFetch is AuthAuthenticated &&
        _hasCompleteContext(stateAfterFetch.user) &&
        !_hasCompleteContext(resolved)) {
      return;
    }

    await _loadPermissionsFromCache(resolved);
    _emitAuthenticated(emit, resolved);
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(type: AuthLoadingType.passwordReset));
    try {
      await sendPasswordResetOtp(event.email);
      _pendingResetEmail = event.email;
      emit(AuthResetCodeSent(event.email));
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
    }
  }

  Future<void> _onVerifyResetCode(
    AuthVerifyResetCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(type: AuthLoadingType.passwordReset));
    try {
      final email = _pendingResetEmail ?? event.email;
      await verifyPasswordResetOtp(email: email, token: event.code);
      emit(AuthResetCodeVerified(email));
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
    }
  }

  Future<void> _onResetPassword(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(type: AuthLoadingType.passwordReset));
    try {
      await resetPassword(event.newPassword);
      _pendingResetEmail = null;
      emit(AuthPasswordResetSuccess());
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
    }
  }

  Future<void> _onResendResetCode(
    AuthResendResetCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(type: AuthLoadingType.passwordReset));
    try {
      final email = _pendingResetEmail ?? event.email;
      await sendPasswordResetOtp(email);
      _pendingResetEmail = email;
      emit(AuthResetCodeSent(email));
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
