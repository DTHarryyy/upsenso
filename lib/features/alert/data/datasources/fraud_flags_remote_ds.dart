import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/database/app_database.dart';

/// The server already holds this incident (same business + dedupe_key) under
/// a different row id — a benign race between two devices sweeping the same
/// mirror data. The local duplicate gets superseded, never retried.
class FraudFlagDedupeConflict implements Exception {
  final String flagId;
  FraudFlagDedupeConflict(this.flagId);

  @override
  String toString() => 'FraudFlagDedupeConflict($flagId)';
}

/// Supabase payload for a local fraud flag row. evidence/related_ids are
/// stored as JSON *text* locally but the server columns are jsonb — sending
/// the raw string makes Postgres store a jsonb STRING SCALAR (double-encoded)
/// instead of the array, so it can't be read back on pull (the same bug that
/// corrupted audit metadata). Decode to the object so jsonb stores it
/// faithfully.
Map<String, dynamic> fraudFlagToRemoteRow(FraudFlagRow r) {
  return {
    'id': r.id,
    'business_id': r.businessId,
    'branch_id': (r.branchId?.isEmpty ?? true) ? null : r.branchId,
    'rule_code': r.ruleCode,
    'severity': r.severity,
    'status': r.status,
    'title': r.title,
    'description': r.description,
    'subject_user_id': r.subjectUserId,
    'evidence': _decodeJson(r.evidence, const []),
    'related_ids': _decodeJson(r.relatedIds, const []),
    'resolved_by': r.resolvedBy,
    'resolution_note': r.resolutionNote,
    'detected_at': r.detectedAt.toUtc().toIso8601String(),
    'created_at': r.createdAt.toUtc().toIso8601String(),
    'updated_at': r.updatedAt.toUtc().toIso8601String(),
    'client_updated_at': r.clientUpdatedAt.toUtc().toIso8601String(),
    'deleted_at': r.deletedAt?.toUtc().toIso8601String(),
    'dedupe_key': r.dedupeKey,
  };
}

/// Decodes locally-stored JSON text to the object jsonb should hold; falls
/// back to [fallback] on empty/corrupt input so a bad row still syncs.
Object _decodeJson(String raw, Object fallback) {
  if (raw.isEmpty) return fallback;
  try {
    return jsonDecode(raw) as Object;
  } catch (_) {
    return fallback;
  }
}

class FraudFlagsRemoteDs {
  final SupabaseClient _client;

  FraudFlagsRemoteDs(this._client);

  /// INSERT only — the server freeze trigger forbids replacing a flag's
  /// forensic content, so there is deliberately no upsert path.
  Future<void> insertFlag(Map<String, dynamic> row) async {
    try {
      await _client.from('fraud_flags').insert(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final text = '${e.message} ${e.details ?? ''}';
        if (text.contains('ux_fraud_flags_dedupe')) {
          throw FraudFlagDedupeConflict(row['id'] as String? ?? '');
        }
        return; // duplicate id: this exact row already synced
      }
      rethrow;
    }
  }

  /// Triage-only update — the same field set the freeze trigger allows.
  /// RLS additionally enforces fraud.resolve + branch + the
  /// self-resolution block; a denial surfaces as an error here.
  Future<void> updateTriage(FraudFlagRow r) async {
    await _client.from('fraud_flags').update({
      'status': r.status,
      'resolved_by': r.resolvedBy,
      'resolution_note': r.resolutionNote,
      'deleted_at': r.deletedAt?.toUtc().toIso8601String(),
      'client_updated_at': r.clientUpdatedAt.toUtc().toIso8601String(),
    }).eq('id', r.id);
  }

  /// Flag volume is small (deduped incidents, not events) — a full tenant
  /// pull keeps every device's triage state converged.
  Future<List<Map<String, dynamic>>> getFlagsByBusiness(
    String businessId,
  ) async {
    final res = await _client
        .from('fraud_flags')
        .select()
        .eq('business_id', businessId)
        .order('detected_at', ascending: false)
        .limit(500);
    return List<Map<String, dynamic>>.from(res as List);
  }
}
