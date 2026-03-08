import '../repositories/auth_repository.dart';

class VerifyPasswordResetOtp {
  final AuthRepository repo;
  VerifyPasswordResetOtp(this.repo);

  Future<void> call({required String email, required String token}) =>
      repo.verifyPasswordResetOtp(email: email, token: token);
}
