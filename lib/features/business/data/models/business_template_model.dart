import '../../domain/entities/business_template.dart';

class BusinessTemplateModel extends BusinessTemplate {
  const BusinessTemplateModel({
    required super.id,
    required super.code,
    required super.name,
    super.description,
    super.version,
    super.isActive,
    super.createdAt,
  });

  factory BusinessTemplateModel.fromJson(Map<String, dynamic> json) {
    return BusinessTemplateModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'description': description,
    'version': version,
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
  };
}
