import '../../domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    super.email,
    super.fullName,
    super.avatarUrl,
    super.businessId,
    super.roleId,
    super.roleName,
    super.businessName,
    super.branchId,
    super.branchName,
    super.businessTemplateId,
    super.businessTemplateName,
  });

  factory AppUserModel.fromSupabaseUser(User user) {
    return AppUserModel(
      id: user.id,
      email: user.email,
      fullName: user.userMetadata?['full_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }

  AppUserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? businessId,
    String? roleId,
    String? roleName,
    String? businessName,
    String? branchId,
    String? branchName,
    String? businessTemplateId,
    String? businessTemplateName,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      businessId: businessId ?? this.businessId,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      businessName: businessName ?? this.businessName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      businessTemplateId: businessTemplateId ?? this.businessTemplateId,
      businessTemplateName: businessTemplateName ?? this.businessTemplateName,
    );
  }
}
