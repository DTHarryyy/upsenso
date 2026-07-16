import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';

/// Reconnaissance detector: before abusing anything, a knowledgeable insider
/// maps the fence — trying gated screens and actions to learn what's
/// watched. Every denial is already audit-logged; many denials across many
/// DISTINCT permissions in one day looks nothing like normal use (which
/// bumps into the same one or two walls).
class PermissionProbingRule implements FraudRule {
  @override
  String get code => 'PERMISSION_PROBING';

  @override
  bool get requiresFullAuditMirror => false;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    final rows = await ctx.db
        .customSelect(
          'SELECT id, user_id, branch_id, metadata, created_at, '
          "DATE(created_at,'unixepoch','localtime') AS day "
          'FROM audit_logs '
          "WHERE business_id = ? AND action_type = 'PERMISSION_DENIED' "
          // Ordered so each group's LAST row really is the newest denial —
          // detectedAt and branch attribution come from it.
          'AND created_at >= ? ORDER BY created_at ASC',
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(ctx.windowStartUnix),
          ],
        )
        .get();
    if (rows.isEmpty) return const [];

    // Group denials per (user, local day); count distinct permissions from
    // the metadata (fall back to count-only when metadata is unparsable).
    final groups = <String, List<QueryRow>>{};
    for (final r in rows) {
      final user = r.read<String>('user_id');
      if (user.isEmpty) continue;
      groups.putIfAbsent('$user|${r.read<String>('day')}', () => []).add(r);
    }

    final drafts = <FraudFlagDraft>[];
    for (final entry in groups.entries) {
      final denials = entry.value;
      if (denials.length < FraudDefaults.probingDenialsPerDay) continue;

      final perms = <String>{};
      for (final r in denials) {
        try {
          final meta = jsonDecode(r.read<String>('metadata'));
          final p = (meta as Map)['permission']?.toString();
          if (p != null && p.isNotEmpty) perms.add(p);
        } catch (_) {
          // Unparsable metadata — the count criterion still applies.
        }
      }
      if (perms.isNotEmpty && perms.length < FraudDefaults.probingDistinctPerms) {
        continue; // hitting the same wall repeatedly is frustration, not recon
      }

      final parts = entry.key.split('|');
      final user = parts[0];
      final day = parts[1];
      final last = denials.last;
      drafts.add(FraudFlagDraft(
        ruleCode: code,
        severity: FraudSeverity.medium,
        title: 'Repeated permission-denied attempts',
        description:
            '${denials.length} denied action(s) across '
            '${perms.isEmpty ? 'several' : perms.length} different '
            'permission(s) by one employee on $day — probing what the system '
            'allows.',
        dedupeKey: '$code|$user|$day',
        detectedAt: DateTime.fromMillisecondsSinceEpoch(
          last.read<int>('created_at') * 1000,
        ),
        branchId: (last.readNullable<String>('branch_id') ?? '').isEmpty
            ? null
            : last.read<String>('branch_id'),
        subjectUserId: user,
        evidence: [
          {'fact': 'Denied attempts', 'value': denials.length, 'window': day},
          {'fact': 'Distinct permissions tried', 'value': perms.length},
          if (perms.isNotEmpty)
            {'fact': 'Permissions', 'value': perms.take(8).join(', ')},
        ],
        relatedIds: [
          for (final r in denials.take(10)) r.read<String>('id'),
        ],
      ));
    }
    return drafts;
  }
}
