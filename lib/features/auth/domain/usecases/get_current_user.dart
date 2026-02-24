import 'package:pos/features/auth/domain/entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repo;
  GetCurrentUser(this.repo);

  AppUser? call() => repo.getCurrentUser();
}
