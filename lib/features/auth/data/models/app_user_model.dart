import '../../domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    super.email,
    super.fullName,
    super.businessId,
    super.roleId,
    super.businessName,
  });

  factory AppUserModel.fromSupabaseUser(User user) {
    return AppUserModel(
      id: user.id,
      email: user.email,
      fullName: user.userMetadata?['full_name'] as String?,
    );
  }

  AppUserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? businessId,
    String? roleId,
    String? businessName,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      businessId: businessId ?? this.businessId,
      roleId: roleId ?? this.roleId,
      businessName: businessName ?? this.businessName,
    );
  }
}
