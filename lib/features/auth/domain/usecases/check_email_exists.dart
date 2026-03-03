import '../repositories/auth_repository.dart';

class CheckEmailExists {
  final AuthRepository repo;
  CheckEmailExists(this.repo);

  Future<bool> call(String email) {
    return repo.checkEmailExists(email);
  }
}
