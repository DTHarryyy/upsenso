import 'package:equatable/equatable.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthUnknown extends AuthState {}

class AuthLoading extends AuthState {}

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
    user.businessName,
  ];
}

class AuthUnauthenticated extends AuthState {}

class AuthCodeSent extends AuthState {
  final String email;
  const AuthCodeSent(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
