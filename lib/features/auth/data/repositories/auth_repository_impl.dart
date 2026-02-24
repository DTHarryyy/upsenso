import 'package:pos/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:pos/features/auth/data/models/app_user_model.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDs remote;
  AuthRepositoryImpl(this.remote);

  @override
  AppUser? getCurrentUser() {
    final user = remote.currentUser();
    return user == null ? null : AppUserModel.fromSupabaseUser(user);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return remote.onAuthStateChange().map((state) {
      final user = state.session?.user;
      return user == null ? null : AppUserModel.fromSupabaseUser(user);
    });
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final res = await remote.signIn(email, password);
    final user = res.user;
    if (user == null) throw Exception('Sign-in failed (no user).');
    return AppUserModel.fromSupabaseUser(user);
  }

  @override
  Future<AppUser> signUp(String email, String password) async {
    final res = await remote.signUp(email, password);
    final user = res.user;
    if (user == null) throw Exception('Sign-up failed (no user).');
    return AppUserModel.fromSupabaseUser(user);
  }

  @override
  Future<void> signOut() => remote.signOut();
}
