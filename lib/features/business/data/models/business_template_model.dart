import '../../domain/entities/business_template.dart';

class BusinessTemplateModel extends BusinessTemplate {
  const BusinessTemplateModel({
    required super.id,
    required super.name,
    required super.defaultModules,
    required super.defaultRoles,
    required super.defaultPermissions,
    super.defaultTaxRate,
    super.createdAt,
  });

  factory BusinessTemplateModel.fromJson(Map<String, dynamic> json) {
    return BusinessTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      defaultModules: Map<String, dynamic>.from(json['default_modules'] ?? {}),
      defaultRoles:
          (json['default_roles'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      defaultPermissions: Map<String, dynamic>.from(
        json['default_permissions'] ?? {},
      ),
      defaultTaxRate: json['default_tax_rate'] != null
          ? (json['default_tax_rate'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'default_modules': defaultModules,
      'default_roles': defaultRoles,
      'default_permissions': defaultPermissions,
      'default_tax_rate': defaultTaxRate,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
