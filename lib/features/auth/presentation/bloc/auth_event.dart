import 'package:equatable/equatable.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthUserContextUpdated extends AuthEvent {
  final AppUser user;
  const AuthUserContextUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

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

// Password Reset Events
class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  const AuthForgotPasswordRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthVerifyResetCodeRequested extends AuthEvent {
  final String email;
  final String code;
  const AuthVerifyResetCodeRequested(this.email, this.code);

  @override
  List<Object?> get props => [email, code];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String newPassword;
  const AuthResetPasswordRequested(this.newPassword);

  @override
  List<Object?> get props => [newPassword];
}

class AuthResendResetCodeRequested extends AuthEvent {
  final String email;
  const AuthResendResetCodeRequested(this.email);

  @override
  List<Object?> get props => [email];
}
