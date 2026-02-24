import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/observe_auth_state.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser getCurrentUser;
  final ObserveAuthState observeAuthState;
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;

  StreamSubscription? _sub;

  AuthBloc({
    required this.getCurrentUser,
    required this.observeAuthState,
    required this.signIn,
    required this.signUp,
    required this.signOut,
  }) : super(AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
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
      emit(AuthError(err.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await signUp(e.email, e.password);
      emit(AuthAuthenticated(user));
    } catch (err) {
      emit(AuthError(err.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await signOut();
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
