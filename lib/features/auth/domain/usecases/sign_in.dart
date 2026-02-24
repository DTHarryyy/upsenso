import 'package:pos/features/auth/domain/entities/app_user.dart';

import '../repositories/auth_repository.dart';

class SignIn {
  final AuthRepository repo;
  SignIn(this.repo);

  Future<AppUser> call(String email, String password) =>
      repo.signIn(email, password);
}
