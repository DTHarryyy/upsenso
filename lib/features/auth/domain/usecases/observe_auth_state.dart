import 'package:pos/features/auth/domain/entities/app_user.dart';
import '../repositories/auth_repository.dart';

class ObserveAuthState {
  final AuthRepository repo;
  ObserveAuthState(this.repo);

  Stream<AppUser?> call() => repo.authStateChanges();
}
