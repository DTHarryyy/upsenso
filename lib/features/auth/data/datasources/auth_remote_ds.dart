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

  Future<void> signOut() => client.auth.signOut();
}
