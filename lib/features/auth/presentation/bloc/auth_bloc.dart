import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/errors/supabase_error_mapper.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';

import '../../domain/usecases/check_email_exists.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/get_user_business_context.dart';
import '../../domain/usecases/observe_auth_state.dart';
import '../../domain/usecases/send_sign_up_otp.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_in_with_facebook.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
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

  StreamSubscription? _sub;
  String? _pendingSignUpEmail;
  String? _pendingSignUpPassword;

  String _errorMessage(Object err) {
    if (err is String) return err;
    return SupabaseAuthErrorMapper.message(err);
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  Future<AppUser?> _getUserContextWithRetry(String userId) async {
    // Trigger-created rows can appear a moment after auth state changes.
    AppUser? latest;
    for (var attempt = 0; attempt < 8; attempt++) {
      final userWithContext = await getUserBusinessContext(userId);
      latest = userWithContext;

      if (userWithContext != null) {
        final hasBusiness = _hasText(userWithContext.businessId);
        final hasRole =
            _hasText(userWithContext.roleId) ||
            _hasText(userWithContext.roleName);

        // No business means user still needs setup; return immediately.
        if (!hasBusiness) {
          return userWithContext;
        }

        // Business + role is the fully hydrated context we need.
        if (hasRole) {
          return userWithContext;
        }
      }

      if (attempt < 7) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
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
  }) : super(AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthFacebookSignInRequested>(_onFacebookSignIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthVerifySignUpCodeRequested>(_onVerifySignUpCode);
    on<AuthResendSignUpCodeRequested>(_onResendSignUpCode);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthUserChanged>(_onUserChanged);

    _sub = observeAuthState().listen((user) {
      add(AuthUserChanged(user != null));
    });
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final user = getCurrentUser();
    if (user != null) {
      // Fetch updated user info with business context
      final updatedUser = await _getUserContextWithRetry(user.id);
      emit(
        updatedUser != null
            ? AuthAuthenticated(updatedUser)
            : AuthAuthenticated(user),
      );
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading(type: AuthLoadingType.email));
    try {
      final user = await signIn(e.email, e.password);
      // Fetch user business context
      final userWithContext = await _getUserContextWithRetry(user.id);
      emit(
        userWithContext != null
            ? AuthAuthenticated(userWithContext)
            : AuthAuthenticated(user),
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
      // OAuth opens in browser/webview - show in-progress state until user returns
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
      // OAuth opens in browser/webview - show in-progress state until user returns
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
      // Check if email already exists
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

      final user = await verifySignUpOtp(
        email: e.email,
        token: e.code,
        password: pendingPassword,
      );

      _pendingSignUpEmail = null;
      _pendingSignUpPassword = null;

      // Fetch user business context
      final userWithContext = await _getUserContextWithRetry(user.id);
      emit(
        userWithContext != null
            ? AuthAuthenticated(userWithContext)
            : AuthAuthenticated(user),
      );
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
    try {
      await signOut();
      _pendingSignUpEmail = null;
      _pendingSignUpPassword = null;
      emit(AuthUnauthenticated());
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
      final user = getCurrentUser();
      emit(user == null ? AuthUnauthenticated() : AuthAuthenticated(user));
    }
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (!event.isLoggedIn) {
      // Keep offline session usable if local cache still has user context.
      final cachedUser = getCurrentUser();
      if (cachedUser != null) {
        emit(AuthAuthenticated(cachedUser));
        return;
      }

      emit(AuthUnauthenticated());
      return;
    }

    final user = getCurrentUser();
    if (user == null) {
      emit(AuthUnauthenticated());
      return;
    }

    final userWithContext = await _getUserContextWithRetry(user.id);
    emit(
      userWithContext != null
          ? AuthAuthenticated(userWithContext)
          : AuthAuthenticated(user),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
