import '../repositories/auth_repository.dart';

class SignInWithFacebook {
  final AuthRepository repo;

  SignInWithFacebook(this.repo);

  Future<void> call() => repo.signInWithFacebook();
}
