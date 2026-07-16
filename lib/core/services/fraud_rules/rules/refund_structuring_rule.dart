import 'package:drift/drift.dart';

import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';

/// The anti-insider marquee rule: an employee who KNOWS refunds over the
/// approval threshold need a manager PIN, and keeps their refunds just
/// below it. Repeated refunds landing in the 70–100% band of the threshold
/// within 7 days are exactly that pattern — a fixed-threshold system never
/// fires here by design.
class RefundStructuringRule implements FraudRule {
  @override
  String get code => 'REFUND_STRUCTURING';

  @override
  bool get requiresFullAuditMirror => false;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    final settings = await ctx.db
        .customSelect(
          'SELECT require_approval, approval_threshold FROM refund_settings '
          'WHERE business_id = ? LIMIT 1',
          variables: [Variable.withString(ctx.businessId)],
        )
        .getSingleOrNull();
    if (settings == null) return const [];
    final requireApproval = settings.read<bool>('require_approval');
    final threshold = settings.read<double>('approval_threshold');
    // No approval gate = nothing to structure under.
    if (!requireApproval || threshold <= 0) return const [];

    final sevenDaysAgo =
        ctx.now.subtract(const Duration(days: 7)).toUtc().millisecondsSinceEpoch ~/
            1000;
    final bandLow = threshold * FraudDefaults.structuringBandLow;

    // Grouped per employee ACROSS branches — structuring is a per-person
    // pattern, and splitting it over branches must not divide the count
    // under the threshold (nor mint colliding dedupe keys per branch).
    final rows = await ctx.db
        .customSelect(
          'SELECT refunded_by, COUNT(*) AS cnt, '
          'SUM(total_amount) AS val, MAX(created_at) AS last_at, '
          "DATE(MAX(created_at),'unixepoch','localtime') AS last_day, "
          'COUNT(DISTINCT branch_id) AS branch_cnt, '
          'MIN(branch_id) AS branch_one '
          'FROM refunds '
          'WHERE business_id = ? AND created_at >= ? AND deleted_at IS NULL '
          'AND total_amount >= ? AND total_amount < ? '
          'GROUP BY refunded_by '
          'HAVING cnt >= ?',
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(sevenDaysAgo),
            Variable<double>(bandLow),
            Variable<double>(threshold),
            Variable<int>(FraudDefaults.structuringCount7d),
          ],
        )
        .get();

    final drafts = <FraudFlagDraft>[];
    for (final r in rows) {
      final user = r.read<String>('refunded_by');
      final cnt = r.read<int>('cnt');
      final value = r.read<double>('val');
      final lastDay = r.read<String>('last_day');

      final relatedIds = await _bandRefundIds(ctx, user, sevenDaysAgo, bandLow, threshold);
      drafts.add(FraudFlagDraft(
        ruleCode: code,
        severity: FraudSeverity.high,
        title: 'Refunds clustered just below the approval threshold',
        description:
            '$cnt refund(s) by one employee in 7 days landed between '
            '₱${bandLow.toStringAsFixed(2)} and ₱${threshold.toStringAsFixed(2)} '
            '— just under the amount that requires manager approval.',
        dedupeKey: '$code|$user|$lastDay',
        detectedAt: DateTime.fromMillisecondsSinceEpoch(
          r.read<int>('last_at') * 1000,
        ),
        branchId: r.read<int>('branch_cnt') == 1
            ? r.readNullable<String>('branch_one')
            : null,
        subjectUserId: user,
        evidence: [
          {'fact': 'Refunds in the 70–100% band', 'value': cnt, 'window': '7 days'},
          {'fact': 'Band value total', 'value': value},
          {'fact': 'Approval threshold', 'value': threshold},
        ],
        relatedIds: relatedIds,
      ));
    }
    return drafts;
  }

  Future<List<String>> _bandRefundIds(
    FraudScanContext ctx,
    String user,
    int since,
    double bandLow,
    double threshold,
  ) async {
    final rows = await ctx.db
        .customSelect(
          'SELECT id FROM refunds '
          'WHERE business_id = ? AND refunded_by = ? AND created_at >= ? '
          'AND total_amount >= ? AND total_amount < ? AND deleted_at IS NULL '
          'LIMIT 20',
          variables: [
            Variable.withString(ctx.businessId),
            Variable.withString(user),
            Variable<int>(since),
            Variable<double>(bandLow),
            Variable<double>(threshold),
          ],
        )
        .get();
    return [for (final r in rows) r.read<String>('id')];
  }
}
