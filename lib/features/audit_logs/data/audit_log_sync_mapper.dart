import 'package:pos/core/database/app_database.dart';

/// Builds the Supabase `audit_logs` payload for a local row.
///
/// Kept apart from SyncService so the entity_id sanitization stays unit-testable
/// without standing up the whole sync stack.
Map<String, dynamic> auditLogToRemoteRow(AuditLogRow r) {
  // entity_id is uuid-typed remotely; drop non-uuid values (e.g. module codes)
  // so the log still syncs instead of erroring forever — the code is preserved
  // in metadata/entity_name.
  final entityId = (r.entityId?.isEmpty ?? true) ? null : r.entityId;
  return {
    'id': r.id,
    'business_id': r.businessId,
    'branch_id': r.branchId.isEmpty ? null : r.branchId,
    'user_id': r.userId.isEmpty ? null : r.userId,
    'action_type': r.actionType,
    'entity_type': r.entityType,
    'entity_id': isUuid(entityId) ? entityId : null,
    'description': r.description,
    'metadata': r.metadata,
    'device_id': r.deviceId,
    'created_at': r.createdAt.toUtc().toIso8601String(),
  };
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// True when [value] is a canonical 8-4-4-4-12 hex UUID.
bool isUuid(String? value) => value != null && _uuidPattern.hasMatch(value);
