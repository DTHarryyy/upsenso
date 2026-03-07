import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';

/// Usecase to fetch the user's current business context
/// Returns updated user with businessId, roleId, and businessName
class GetUserBusinessContext {
  final AuthRepository repo;

  GetUserBusinessContext(this.repo);

  Future<AppUser?> call(String userId) {
    return repo.getUserBusinessContext(userId);
  }
}
