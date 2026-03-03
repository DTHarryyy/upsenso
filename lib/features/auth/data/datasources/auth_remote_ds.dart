import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDs {
  final SupabaseClient client;
  AuthRemoteDs(this.client);

  User? currentUser() => client.auth.currentUser;

  Stream<AuthState> onAuthStateChange() => client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) {
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> sendSignUpOtp(String email) async {
    await client.auth.signInWithOtp(email: email, shouldCreateUser: true);
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      // Try to send OTP without creating user
      // If user exists, this will succeed; if not, it will throw an error
      await client.auth.signInWithOtp(email: email, shouldCreateUser: false);
      return true; // User exists
    } catch (e) {
      if (e is AuthException) {
        final msg = e.message.toLowerCase();

        // If error indicates user doesn't exist, return false
        if (msg.contains('not found') ||
            msg.contains('does not exist') ||
            msg.contains('no user') ||
            msg.contains('user not found')) {
          return false; // User doesn't exist
        }

        // If it's a configuration error (signups disabled, email provider, etc.),
        // return false to proceed with signup which will catch the actual error
        if (msg.contains('signups not allowed') ||
            msg.contains('signup is disabled') ||
            msg.contains('email signups are disabled') ||
            msg.contains('email provider') ||
            msg.contains('smtp') ||
            msg.contains('disabled')) {
          return false; // Can't verify, let signup process handle it
        }
      }

      // For any other error, return false to let the signup flow handle it
      return false;
    }
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => client.auth.signOut();
}
