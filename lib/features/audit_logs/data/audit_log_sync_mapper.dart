import 'dart:convert';

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
    // The local column stores metadata as JSON *text*; the server column is
    // jsonb. Sending the raw string makes Postgres store a jsonb STRING
    // SCALAR (double-encoded) rather than an object — which then can't be
    // parsed back on pull and corrupts the hash-verified metadata. Decode to
    // the object so jsonb stores it faithfully.
    'metadata': decodeMetadataForRemote(r.metadata),
    'device_id': r.deviceId,
    'created_at': r.createdAt.toUtc().toIso8601String(),
    // Chain fields (M1). Server columns previous_hash/hash predate the
    // feature and are adopted as-is; pre-chain rows push NULLs, which the
    // partial ux_audit_chain index exempts.
    'seq': r.seq,
    'previous_hash': r.prevHash,
    'hash': r.entryHash,
    'device_uid': r.deviceUid,
    // Canonicalization version so another device's verifier knows whether it
    // can recompute this row's hash (v2+) or must treat it as legacy.
    'hash_version': r.hashVersion,
  };
}

/// Decodes the locally-stored metadata JSON text into the object jsonb should
/// hold. Falls back to an empty object if the text isn't valid JSON, so a
/// corrupt row still syncs instead of erroring forever.
Object decodeMetadataForRemote(String raw) {
  if (raw.isEmpty) return const <String, dynamic>{};
  try {
    return jsonDecode(raw) as Object;
  } catch (_) {
    return const <String, dynamic>{};
  }
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// True when [value] is a canonical 8-4-4-4-12 hex UUID.
bool isUuid(String? value) => value != null && _uuidPattern.hasMatch(value);
