import '../../domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUserModel extends AppUser {
  const AppUserModel({required super.id, super.email});

  factory AppUserModel.fromSupabaseUser(User user) {
    return AppUserModel(id: user.id, email: user.email);
  }
}
