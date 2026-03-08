import 'package:equatable/equatable.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthUnknown extends AuthState {}

enum AuthLoadingType {
  email,
  google,
  facebook, // wag muna makapasadut i implement nu maminsan tun
  signUp,
  verifyCode,
  passwordReset,
}

class AuthLoading extends AuthState {
  final AuthLoadingType? type;
  const AuthLoading({this.type});

  @override
  List<Object?> get props => [type];
}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [
    user.id,
    user.email,
    user.fullName,
    user.businessId,
    user.roleId,
    user.roleName,
    user.businessName,
    user.branchId,
    user.branchName,
  ];
}

class AuthUnauthenticated extends AuthState {}

class AuthOAuthInProgress extends AuthState {
  final String provider;
  const AuthOAuthInProgress(this.provider);

  @override
  List<Object?> get props => [provider];
}

class AuthCodeSent extends AuthState {
  final String email;
  const AuthCodeSent(this.email);

  @override
  List<Object?> get props => [email];
}

// Password Reset States
class AuthResetCodeSent extends AuthState {
  final String email;
  const AuthResetCodeSent(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthResetCodeVerified extends AuthState {
  final String email;
  const AuthResetCodeVerified(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthPasswordResetSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
