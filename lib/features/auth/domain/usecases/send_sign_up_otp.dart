import '../repositories/auth_repository.dart';

class SendSignUpOtp {
  final AuthRepository repo;
  SendSignUpOtp(this.repo);

  Future<void> call(String email) => repo.sendSignUpOtp(email);
}
