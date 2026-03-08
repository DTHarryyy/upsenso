import '../repositories/auth_repository.dart';

class ResetPassword {
  final AuthRepository repo;
  ResetPassword(this.repo);

  Future<void> call(String newPassword) => repo.resetPassword(newPassword);
}
