// Canonical serialization + hashing for the tamper-evident audit chain.
//
// This is the SINGLE serializer used by both the writer (AuditLogService)
// and the verifier (AuditChainVerifier). Determinism is everything: both
// sides must produce byte-identical input for the same row, on every
// platform (VM and web), before and after a Supabase roundtrip.
import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Genesis sentinel: `prev_hash` of the first entry in a device chain.
const String kAuditGenesisHash =
    '0000000000000000000000000000000000000000000000000000000000000000';

/// Canonicalization version stamped on newly written rows
/// (audit_logs.hash_version). Rows with NULL/1 predate v2 and are
/// grandfathered: the verifier runs link/seq checks on them but skips the
/// hash recompute, because their canonical form can no longer be reproduced
/// bit-exactly (pre-fix metadata double-encoding, ''-vs-NULL drift).
const int kAuditHashVersion = 2;

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// True when [value] is a canonical 8-4-4-4-12 hex UUID.
///
/// The server's `entity_id` column is uuid-typed, so the sync mapper nulls
/// non-UUID values on push. The hash must apply the same normalization or a
/// row would verify locally but "break" after a server roundtrip.
bool isCanonicalUuid(String? value) =>
    value != null && _uuidPattern.hasMatch(value);

/// Truncates to whole seconds, in UTC.
///
/// Drift stores DateTimes as unix epoch SECONDS — hashing anything finer
/// would never survive a read-back. The writer must stamp rows with this.
DateTime auditChainTimestamp(DateTime dt) {
  final ms = dt.toUtc().millisecondsSinceEpoch;
  return DateTime.fromMillisecondsSinceEpoch((ms ~/ 1000) * 1000, isUtc: true);
}

/// Fixed-format UTC ISO-8601 with milliseconds: `2026-07-03T12:34:56.000Z`.
/// Never the platform/locale-dependent `toIso8601String()` (microseconds).
String formatAuditTimestamp(DateTime dt) {
  final u = dt.toUtc();
  String p2(int v) => v.toString().padLeft(2, '0');
  String p3(int v) => v.toString().padLeft(3, '0');
  return '${u.year.toString().padLeft(4, '0')}-${p2(u.month)}-${p2(u.day)}'
      'T${p2(u.hour)}:${p2(u.minute)}:${p2(u.second)}.${p3(u.millisecond)}Z';
}

/// Canonical payload for one audit row: sorted keys, no whitespace,
/// platform-independent scalar encoding.
///
/// [metadataJson] is the JSON string exactly as stored on the row; it is
/// decoded and re-canonicalized so key order / server jsonb normalization
/// can't drift the hash. Sync fields and the hashes themselves are excluded
/// by construction. [entityId] is normalized like the sync mapper (see
/// [isCanonicalUuid]).
///
/// [version] selects the canonical rules the row was hashed under. v2 makes
/// the storage roundtrip invariant EXPLICIT: an empty branch_id/user_id
/// hashes as null — the same value the sync mapper ships and the server
/// stores — instead of relying on the pull path coercing NULL back to ''.
String canonicalAuditPayload({
  required String actionType,
  required String branchId,
  required String businessId,
  required DateTime createdAt,
  required String description,
  required String deviceUid,
  required String? entityId,
  required String entityType,
  required String metadataJson,
  required int seq,
  required String userId,
  int version = kAuditHashVersion,
}) {
  Object? metadata;
  try {
    metadata = metadataJson.isEmpty ? <String, Object?>{} : jsonDecode(metadataJson);
  } on FormatException {
    // A corrupted metadata string still hashes deterministically — as a raw
    // string — so tampering shows up as a break instead of a crash.
    metadata = metadataJson;
  }
  final v2 = version >= 2;
  final map = <String, Object?>{
    'action_type': actionType,
    'branch_id': v2 && branchId.isEmpty ? null : branchId,
    'business_id': businessId,
    'created_at': formatAuditTimestamp(createdAt),
    'description': description,
    'device_uid': deviceUid,
    'entity_id': isCanonicalUuid(entityId) ? entityId : null,
    'entity_type': entityType,
    'metadata': metadata,
    'seq': seq,
    'user_id': v2 && userId.isEmpty ? null : userId,
  };
  final buf = StringBuffer();
  _encodeCanonical(map, buf);
  return buf.toString();
}

/// `entry_hash = SHA256(prev_hash + '|' + canonical_payload)`.
String auditEntryHash({
  required String prevHash,
  required String canonicalPayload,
}) {
  return sha256.convert(utf8.encode('$prevHash|$canonicalPayload')).toString();
}

/// Canonical JSON encoder. jsonEncode is NOT used for structure because its
/// double rendering differs between the VM ("1.0") and dart2js ("1") — the
/// one platform split that would silently fork writer and verifier hashes.
void _encodeCanonical(Object? value, StringBuffer out) {
  if (value == null) {
    out.write('null');
  } else if (value is bool) {
    out.write(value ? 'true' : 'false');
  } else if (value is int) {
    out.write(value.toString());
  } else if (value is double) {
    if (value.isFinite && value == value.truncateToDouble()) {
      out.write(BigInt.from(value).toString());
    } else {
      out.write(value.toString());
    }
  } else if (value is String) {
    out.write(jsonEncode(value)); // string escaping alone is platform-stable
  } else if (value is List) {
    out.write('[');
    for (var i = 0; i < value.length; i++) {
      if (i > 0) out.write(',');
      _encodeCanonical(value[i], out);
    }
    out.write(']');
  } else if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    out.write('{');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) out.write(',');
      out.write(jsonEncode(keys[i]));
      out.write(':');
      _encodeCanonical(value[keys[i]], out);
    }
    out.write('}');
  } else {
    // Non-JSON types shouldn't reach a stored metadata string; encode their
    // string form rather than throwing mid-hash.
    out.write(jsonEncode(value.toString()));
  }
}
