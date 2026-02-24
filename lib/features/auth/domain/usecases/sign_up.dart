import 'package:pos/features/auth/domain/entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repo;
  SignUp(this.repo);

  Future<AppUser> call(String email, String password) =>
      repo.signUp(email, password);
}
