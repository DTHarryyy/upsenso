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

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => client.auth.signOut();
}
