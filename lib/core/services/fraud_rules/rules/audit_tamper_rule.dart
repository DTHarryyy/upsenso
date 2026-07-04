import 'package:drift/drift.dart';

import 'package:pos/core/audit/audit_chain_verifier.dart';
import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';

/// The cryptographic verifier found the local chain no longer matches what
/// was recorded. Severity follows the WORST break reason on the device:
/// content breaks (hash/link/seq on own data) are critical; a truncated tail
/// or storage loss is a sync/browser-storage condition first and reads as
/// medium until a content break corroborates it.
///
/// Deliberately does NOT act on `ux_audit_chain` push conflicts: those are a
/// *sync* condition, not tampering, and their common cause is a benign
/// same-device restart (wiped local DB + surviving uid) which self-heals via
/// AuditLogService.reconcileConflictedTail. Feeding push conflicts here
/// produced a false-tamper flood on 2026-07-03; the verifier's hash/link/seq/
/// truncation checks are content-based and can't false-positive that way.
class AuditTamperRule implements FraudRule {
  final AuditChainVerifier _verifier;

  AuditTamperRule({required AuditChainVerifier verifier})
      : _verifier = verifier;

  @override
  String get code => 'AUDIT_TAMPER';

  @override
  bool get requiresFullAuditMirror => false;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    final drafts = <FraudFlagDraft>[];

    final result = await _verifier.verify(businessId: ctx.businessId);
    for (final device in result.devices) {
      if (device.breaks.isEmpty) continue;
      final severity = _severityFor(device.breaks);
      final reasonCounts = _reasonCounts(device.breaks);
      final shortUid = device.deviceUid.length >= 8
          ? device.deviceUid.substring(0, 8)
          : device.deviceUid;

      // One affected branch → scope the flag to it so its manager sees it;
      // several (or none identifiable) → business-wide, with the branches
      // named in the evidence instead of a bare "All branches".
      final branchId =
          device.branchIds.length == 1 ? device.branchIds.first : null;
      final branchNames = await _branchNames(ctx, device.branchIds);

      drafts.add(FraudFlagDraft(
        ruleCode: code,
        severity: severity,
        title: 'Audit trail integrity broken',
        description:
            '${device.breaks.length} integrity issue(s) ($reasonCounts) '
            'detected in the audit chain of "${device.deviceLabel} '
            '($shortUid)"'
            '${branchNames.isNotEmpty ? ' — affects ${branchNames.join(', ')}' : ''}'
            '${severity == FraudSeverity.critical ? ' — recorded history was altered or removed on that device.' : ' — history is incomplete on that device (commonly browser storage eviction or sync lag on web), not necessarily tampering.'}',
        // One flag per device per day, not per break: a verifier finding N
        // breaks (55 on 2026-07-03) must not mint N flags. The break detail
        // lives in evidence; the digest keeps the feed readable.
        dedupeKey: '$code|${device.deviceUid}|${localDayString(ctx.now)}',
        detectedAt: ctx.now,
        branchId: branchId,
        subjectUserId: null,
        evidence: [
          {'fact': 'Device', 'value': '${device.deviceLabel} ($shortUid)'},
          if (branchNames.isNotEmpty)
            {'fact': 'Affected branches', 'value': branchNames.join(', ')},
          for (final b in device.breaks.take(10))
            {
              'fact': b.reason.name,
              'value': 'entry ${b.seq}',
              if (b.expected != null) 'expected': b.expected,
              if (b.actual != null) 'actual': b.actual,
            },
        ],
        relatedIds: const [],
      ));
    }

    return drafts;
  }

  /// Content alteration of this device's own recorded rows is the real
  /// tamper signal. A missing tail (truncation/storage loss) has benign
  /// browser-storage causes and stays medium on its own.
  static String _severityFor(List<AuditChainBreak> breaks) {
    final contentBreak = breaks.any(
      (b) =>
          b.reason == AuditChainBreakReason.hashMismatch ||
          b.reason == AuditChainBreakReason.linkMismatch ||
          b.reason == AuditChainBreakReason.seqGap,
    );
    return contentBreak ? FraudSeverity.critical : FraudSeverity.medium;
  }

  static String _reasonCounts(List<AuditChainBreak> breaks) {
    final counts = <String, int>{};
    for (final b in breaks) {
      counts.update(b.reason.name, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts.entries.map((e) => '${e.value}× ${e.key}').join(', ');
  }

  Future<List<String>> _branchNames(
    FraudScanContext ctx,
    Set<String> branchIds,
  ) async {
    if (branchIds.isEmpty) return const [];
    final names = <String>[];
    for (final id in branchIds.take(5)) {
      final row = await ctx.db
          .customSelect(
            'SELECT name FROM branches WHERE id = ? LIMIT 1',
            variables: [Variable.withString(id)],
          )
          .getSingleOrNull();
      final name = row?.readNullable<String>('name');
      names.add(name?.isNotEmpty == true ? name! : 'Unknown branch');
    }
    return names;
  }
}
