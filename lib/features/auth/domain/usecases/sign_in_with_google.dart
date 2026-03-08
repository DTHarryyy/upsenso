import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository repo;

  SignInWithGoogle(this.repo);

  Future<void> call() => repo.signInWithGoogle();
}
