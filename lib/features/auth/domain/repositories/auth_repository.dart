import '../entities/app_user.dart';

abstract class AuthRepository {
  AppUser? getCurrentUser();
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn(String email, String password);

  Future<AppUser> signUp(String email, String password);
  Future<void> sendSignUpOtp(String email);
  Future<AppUser> verifySignUpOtp({
    required String email,
    required String token,
    required String password,
  });
  Future<void> signOut();
}
