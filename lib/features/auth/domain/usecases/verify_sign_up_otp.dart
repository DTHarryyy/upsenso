import 'package:pos/features/auth/domain/entities/app_user.dart';

import '../repositories/auth_repository.dart';

class VerifySignUpOtp {
  final AuthRepository repo;
  VerifySignUpOtp(this.repo);

  Future<AppUser> call({
    required String email,
    required String token,
    required String password,
  }) {
    return repo.verifySignUpOtp(email: email, token: token, password: password);
  }
}
