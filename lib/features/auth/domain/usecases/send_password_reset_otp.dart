import '../repositories/auth_repository.dart';

class SendPasswordResetOtp {
  final AuthRepository repo;
  SendPasswordResetOtp(this.repo);

  Future<void> call(String email) => repo.sendPasswordResetOtp(email);
}
