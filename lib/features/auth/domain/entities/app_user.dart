class AppUser {
  final String id;
  final String? email;
  final String? fullName;
  final String? businessId;
  final String? roleId;
  final String? businessName;

  const AppUser({
    required this.id,
    this.email,
    this.fullName,
    this.businessId,
    this.roleId,
    this.businessName,
  });
}
