import '../../domain/entities/business.dart';

class BusinessModel extends Business {
  const BusinessModel({
    required super.id,
    required super.name,
    required super.ownerId,
    required super.templateId,
    required super.createdAt,
    required super.isActive,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      templateId: json['template_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'template_id': templateId,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// For creating a new business (without id and created_at)
  static Map<String, dynamic> toCreateJson({
    required String name,
    required String ownerId,
    required String templateId,
    bool isActive = true,
  }) {
    return {
      'name': name,
      'owner_id': ownerId,
      'template_id': templateId,
      'is_active': isActive,
    };
  }
}
