import '../entities/app_user.dart';

abstract class AuthRepository {
  AppUser? getCurrentUser();
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signInWithFacebook();

  Future<AppUser> signUp(String email, String password);
  Future<bool> checkEmailExists(String email);
  Future<void> sendSignUpOtp(String email);
  Future<AppUser> verifySignUpOtp({
    required String email,
    required String token,
    required String password,
  });
  Future<void> signOut();

  /// Fetch user's business context (businessId, roleId, businessName)
  Future<AppUser?> getUserBusinessContext(String userId);
}
