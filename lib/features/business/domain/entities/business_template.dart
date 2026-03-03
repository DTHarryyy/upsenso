class BusinessTemplate {
  final String id;
  final String name;
  final Map<String, dynamic> defaultModules;
  final List<Map<String, dynamic>> defaultRoles;
  final Map<String, dynamic> defaultPermissions;
  final double? defaultTaxRate;
  final DateTime? createdAt;

  const BusinessTemplate({
    required this.id,
    required this.name,
    required this.defaultModules,
    required this.defaultRoles,
    required this.defaultPermissions,
    this.defaultTaxRate,
    this.createdAt,
  });
}
