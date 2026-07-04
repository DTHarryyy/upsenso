import 'package:drift/drift.dart';

import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';

/// Clock manipulation detector. The audit chain's seq is a total order per
/// device that no clock change can alter — so a row whose wall-clock time is
/// EARLIER than its predecessor's beyond tolerance means the device clock
/// was rolled back between writes (backdating a sale, dodging a time-window
/// rule). This is exactly the manipulation offline-first POS is most
/// exposed to, and it's invisible to any rule that trusts created_at.
///
/// Re-chaining awareness (2026-07-03 FP): AuditLogService.reconcileConflicted-
/// Tail transplants a benign conflicted tail to new seq positions while
/// preserving each row's original created_at, so the FIRST row of a
/// transplanted block legitimately reads as "earlier than its predecessor".
/// Those rows carry a `_rechained` marker in metadata; pairs where the later
/// row is re-chained are excluded — a real clock rollback has no such marker.
class TimeReversalRule implements FraudRule {
  @override
  String get code => 'TIME_REVERSAL';

  @override
  bool get requiresFullAuditMirror => false;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    final rows = await ctx.db
        .customSelect(
          'SELECT a.id, a.device_uid, a.seq, a.user_id, a.branch_id, '
          'a.created_at AS at, p.created_at AS prev_at '
          'FROM audit_logs a JOIN audit_logs p '
          'ON p.business_id = a.business_id AND p.device_uid = a.device_uid '
          'AND p.seq = a.seq - 1 '
          'WHERE a.business_id = ? AND a.seq IS NOT NULL '
          'AND a.created_at >= ? '
          'AND a.created_at < p.created_at - ? '
          // A transplanted tail (reconcileConflictedTail) preserves original
          // timestamps under new seqs — not a clock roll. Its rows carry the
          // marker; skip pairs whose later row is re-chained.
          "AND a.metadata NOT LIKE '%\"_rechained\":true%'",
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(ctx.windowStartUnix),
            Variable<int>(FraudDefaults.timeReversalToleranceSeconds),
          ],
        )
        .get();

    return [
      for (final r in rows)
        FraudFlagDraft(
          ruleCode: code,
          severity: FraudSeverity.high,
          title: 'Device clock moved backwards',
          description:
              'An audit entry is timestamped '
              '${((r.read<int>('prev_at') - r.read<int>('at')) / 60).round()} '
              'minute(s) BEFORE the entry written immediately before it on the '
              'same device — the device clock was set back between actions.',
          dedupeKey: '$code|${r.read<String>('device_uid')}|${r.read<int>('seq')}',
          detectedAt: DateTime.fromMillisecondsSinceEpoch(
            r.read<int>('prev_at') * 1000,
          ),
          branchId: (r.readNullable<String>('branch_id') ?? '').isEmpty
              ? null
              : r.read<String>('branch_id'),
          subjectUserId: (r.readNullable<String>('user_id') ?? '').isEmpty
              ? null
              : r.read<String>('user_id'),
          evidence: [
            {'fact': 'Chain position (seq)', 'value': r.read<int>('seq')},
            {
              'fact': 'Clock regression',
              'value':
                  '${((r.read<int>('prev_at') - r.read<int>('at')) / 60).round()} minutes',
              'baseline':
                  'tolerance ${FraudDefaults.timeReversalToleranceSeconds ~/ 60} minutes',
            },
            {'fact': 'Device', 'value': r.read<String>('device_uid')},
          ],
          relatedIds: [r.read<String>('id')],
        ),
    ];
  }
}
