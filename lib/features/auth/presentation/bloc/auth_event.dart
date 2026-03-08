import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthFacebookSignInRequested extends AuthEvent {
  const AuthFacebookSignInRequested();
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthRegisterRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthVerifySignUpCodeRequested extends AuthEvent {
  final String email;
  final String code;
  const AuthVerifySignUpCodeRequested(this.email, this.code);

  @override
  List<Object?> get props => [email, code];
}

class AuthResendSignUpCodeRequested extends AuthEvent {
  final String email;
  const AuthResendSignUpCodeRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final bool isLoggedIn;
  const AuthUserChanged(this.isLoggedIn);

  @override
  List<Object?> get props => [isLoggedIn];
}
