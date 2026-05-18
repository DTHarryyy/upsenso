import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

class AuditLog {
  final String id;
  final String businessId;
  final String branchId;
  final String userId;
  final AuditLogActionType actionType;
  final String entityType;
  final String? entityId;
  final String description;
  final Map<String, dynamic> metadata;
  final String deviceId;
  final DateTime createdAt;
  final int syncStatus;

  const AuditLog({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.userId,
    required this.actionType,
    required this.entityType,
    this.entityId,
    required this.description,
    required this.metadata,
    required this.deviceId,
    required this.createdAt,
    required this.syncStatus,
  });

  /// Human-readable name of the user who performed the action.
  /// Sourced from metadata['_user_name'] when available.
  String? get userName => metadata['_user_name'] as String?;

  /// Human-readable name of the branch where the action occurred.
  /// 'All Branches' for Super Admins with no assigned branch.
  /// Sourced from metadata['_branch_name'] when available.
  String? get branchName => metadata['_branch_name'] as String?;

  /// Human-readable name of the affected entity (e.g. product name).
  /// Sourced from metadata['_entity_name'] when available.
  String? get entityName => metadata['_entity_name'] as String?;
}
