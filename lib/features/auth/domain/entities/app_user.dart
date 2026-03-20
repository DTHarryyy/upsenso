class AppUser {
  final String id;
  final String? email;
  final String? fullName;
  final String? businessId;
  final String? roleId;
  final String? roleName;
  final String? businessName;
  final String? branchId;
  final String? branchName;
  final String? businessTemplateId;
  final String? businessTemplateName;

  const AppUser({
    required this.id,
    this.email,
    this.fullName,
    this.businessId,
    this.roleId,
    this.roleName,
    this.businessName,
    this.branchId,
    this.branchName,
    this.businessTemplateId,
    this.businessTemplateName,
  });
}
