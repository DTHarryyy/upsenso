import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/errors/supabase_error_mapper.dart';

import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/observe_auth_state.dart';
import '../../domain/usecases/send_sign_up_otp.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/verify_sign_up_otp.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser getCurrentUser;
  final ObserveAuthState observeAuthState;
  final SignIn signIn;
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

  AuthBloc({
    required this.getCurrentUser,
    required this.observeAuthState,
    required this.signIn,
    required this.sendSignUpOtp,
    required this.verifySignUpOtp,
    required this.signOut,
  }) : super(AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
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
    emit(user == null ? AuthUnauthenticated() : AuthAuthenticated(user));
  }

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await signIn(e.email, e.password);
      emit(AuthAuthenticated(user));
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
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
    emit(AuthLoading());
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

      emit(AuthAuthenticated(user));
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
    }
  }

  Future<void> _onResendSignUpCode(
    AuthResendSignUpCodeRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await sendSignUpOtp(e.email);
      _pendingSignUpEmail = e.email;
      emit(AuthCodeSent(e.email));
    } catch (err) {
      emit(AuthError(_errorMessage(err)));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await signOut();
    _pendingSignUpEmail = null;
    _pendingSignUpPassword = null;
    emit(AuthUnauthenticated());
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = getCurrentUser();
    emit(user == null ? AuthUnauthenticated() : AuthAuthenticated(user));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
