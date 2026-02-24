import '../entities/app_user.dart';

abstract class AuthRepository {
  AppUser? getCurrentUser();
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn(String email, String password);

  Future<AppUser> signUp(String email, String password);
  Future<void> signOut();
}
