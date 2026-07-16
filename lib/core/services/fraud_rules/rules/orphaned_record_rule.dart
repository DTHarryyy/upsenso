import 'package:drift/drift.dart';

import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';

/// The direct counter to writing AROUND the audit trail (T11): a refund or
/// manual stock movement inserted straight into the database has no audit
/// entry — the chain stays perfectly valid, because nothing was logged. This
/// rule cross-checks financial records against their mandatory audit entries.
///
/// Only meaningful on a device with the FULL audit mirror (audit pull is
/// owner-only): a cashier device holds other devices' refunds but never
/// their audit rows, and would false-positive on every one of them.
class OrphanedRecordRule implements FraudRule {
  @override
  String get code => 'ORPHANED_RECORD';

  @override
  bool get requiresFullAuditMirror => true;

  @override
  Future<List<FraudFlagDraft>?> evaluate(FraudScanContext ctx) async {
    // Records that predate the chain (pre-M1) were legitimately written
    // without per-service audit guarantees — scope to the chain era.
    final m1Start = await ctx.db
        .customSelect(
          'SELECT MIN(created_at) AS m1_start FROM audit_logs '
          'WHERE business_id = ? AND seq IS NOT NULL',
          variables: [Variable.withString(ctx.businessId)],
        )
        .getSingleOrNull();
    final m1StartUnix = m1Start?.readNullable<int>('m1_start');
    if (m1StartUnix == null) return null; // chain era not started — no verdict

    final scanStart =
        m1StartUnix > ctx.windowStartUnix ? m1StartUnix : ctx.windowStartUnix;

    // The orphan verdict is "no local audit row exists" — only trustworthy
    // for records old enough that their audit row would have landed AND that
    // the local mirror has actually caught up to. Two independent cutoffs:
    //  1. grace after the event  — the fire-and-forget audit write lands;
    //  2. grace before the mirror watermark — the owner device has PULLED
    //     audit rows at least this recent from the server.
    // Without (2) a refund created on a cashier device and synced here before
    // its audit row was pulled is falsely orphaned (the 2026-07-03 FP). No
    // watermark yet ⇒ the mirror was never pulled ⇒ we can't judge anything.
    // These gated exits return NULL, not [] — "couldn't judge" must not be
    // mistaken for "scanned clean", or the engine would wipe every pending
    // candidate and restart confirmation on real incidents.
    final mirrorFreshUnix = ctx.auditMirrorFreshUnix;
    if (mirrorFreshUnix == null) return null;
    final eventGraceCutoff = ctx.nowUnix - FraudDefaults.orphanGraceSeconds;
    final mirrorGraceCutoff =
        mirrorFreshUnix - FraudDefaults.orphanGraceSeconds;
    final graceCutoff =
        eventGraceCutoff < mirrorGraceCutoff ? eventGraceCutoff : mirrorGraceCutoff;
    if (graceCutoff < scanStart) return null;

    final drafts = <FraudFlagDraft>[];

    // The NOT EXISTS is scoped to the SAME business and the specific expected
    // action — a stray audit row on another entity can't accidentally satisfy
    // it, and the check reflects the actual required entry, not merely "some
    // row references this id".
    final orphanRefunds = await ctx.db
        .customSelect(
          'SELECT r.id, r.refunded_by, r.branch_id, r.total_amount, '
          'r.created_at FROM refunds r '
          'WHERE r.business_id = ? AND r.created_at >= ? AND r.created_at <= ? '
          'AND r.deleted_at IS NULL '
          'AND NOT EXISTS (SELECT 1 FROM audit_logs a '
          "WHERE a.entity_id = r.id AND a.business_id = r.business_id "
          "AND a.action_type = 'REFUND_CREATED')",
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(scanStart),
            Variable<int>(graceCutoff),
          ],
        )
        .get();
    for (final r in orphanRefunds) {
      drafts.add(FraudFlagDraft(
        ruleCode: code,
        severity: FraudSeverity.high,
        title: 'Refund with no audit trail',
        description:
            'A ₱${r.read<double>('total_amount').toStringAsFixed(2)} refund '
            'exists with no matching audit entry — it did not go through the '
            'app\'s refund flow.',
        dedupeKey: '$code|${r.read<String>('id')}',
        detectedAt: DateTime.fromMillisecondsSinceEpoch(
          r.read<int>('created_at') * 1000,
        ),
        branchId: r.readNullable<String>('branch_id'),
        subjectUserId: r.read<String>('refunded_by'),
        evidence: [
          {'fact': 'Refund amount', 'value': r.read<double>('total_amount')},
          {'fact': 'Expected audit action', 'value': 'REFUND_CREATED'},
        ],
        relatedIds: [r.read<String>('id')],
      ));
    }

    final orphanMovements = await ctx.db
        .customSelect(
          'SELECT l.id, l.branch_id, l.quantity, l.reason, l.created_at '
          'FROM stock_ledger l '
          "WHERE l.business_id = ? AND l.change_type = 'OUT' "
          "AND l.reason IN ('Adjustment','Damage') "
          "AND (l.source_type IS NULL OR l.source_type = 'adjustment') "
          'AND l.created_at >= ? AND l.created_at <= ? '
          'AND NOT EXISTS (SELECT 1 FROM audit_logs a '
          "WHERE a.entity_id = l.id AND a.business_id = l.business_id "
          "AND a.action_type = 'STOCK_ADJUSTED')",
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(scanStart),
            Variable<int>(graceCutoff),
          ],
        )
        .get();
    for (final r in orphanMovements) {
      drafts.add(FraudFlagDraft(
        ruleCode: code,
        severity: FraudSeverity.high,
        title: 'Stock write-off with no audit trail',
        description:
            '${r.read<double>('quantity').toStringAsFixed(1)} unit(s) left '
            'stock as "${r.read<String>('reason')}" with no matching audit '
            'entry — the movement did not go through the app\'s adjustment flow.',
        dedupeKey: '$code|${r.read<String>('id')}',
        detectedAt: DateTime.fromMillisecondsSinceEpoch(
          r.read<int>('created_at') * 1000,
        ),
        branchId: r.readNullable<String>('branch_id'),
        evidence: [
          {'fact': 'Quantity out', 'value': r.read<double>('quantity')},
          {'fact': 'Ledger reason', 'value': r.read<String>('reason')},
          {'fact': 'Expected audit action', 'value': 'STOCK_ADJUSTED'},
        ],
        relatedIds: [r.read<String>('id')],
      ));
    }

    return drafts;
  }
}
