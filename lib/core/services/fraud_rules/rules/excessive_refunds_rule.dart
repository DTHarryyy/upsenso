import 'package:drift/drift.dart';

import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';
import 'package:pos/core/services/fraud_rules/robust_baseline.dart';

/// Refund volume per employee per day — hybrid detection: fixed floors for
/// cold start plus a baseline comparison against every employee-day in the
/// trailing 30 days, so there is no single number to structure under.
class ExcessiveRefundsRule implements FraudRule {
  @override
  String get code => 'EXCESSIVE_REFUNDS';

  @override
  bool get requiresFullAuditMirror => false;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    final baselineStart =
        ctx.now.subtract(const Duration(days: 30)).toUtc().millisecondsSinceEpoch ~/
            1000;

    // One group per (employee, day) ACROSS branches: grouping by branch too
    // would let refunds split over two branches stay under every floor, and
    // two breaching branch-groups would collide on the same dedupe key (the
    // second draft silently dropped with arbitrary branch attribution).
    final rows = await ctx.db
        .customSelect(
          'SELECT refunded_by, '
          "DATE(created_at,'unixepoch','localtime') AS day, "
          'COUNT(*) AS cnt, SUM(total_amount) AS val, '
          'MAX(created_at) AS last_at, '
          'COUNT(DISTINCT branch_id) AS branch_cnt, '
          'MIN(branch_id) AS branch_one '
          'FROM refunds '
          'WHERE business_id = ? AND created_at >= ? AND deleted_at IS NULL '
          'GROUP BY refunded_by, day',
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(baselineStart),
          ],
        )
        .get();

    final windowStartDay = localDayString(ctx.windowStart);
    final allValues = [for (final r in rows) r.read<double>('val')];
    final drafts = <FraudFlagDraft>[];

    for (final r in rows) {
      final day = r.read<String>('day');
      if (day.compareTo(windowStartDay) < 0) continue; // baseline-only sample

      final user = r.read<String>('refunded_by');
      final cnt = r.read<int>('cnt');
      final value = r.read<double>('val');

      final countBreach = cnt > FraudDefaults.excessiveRefundCountPerDay;
      final valueBreach = value > FraudDefaults.excessiveRefundValuePerDay;

      // Baseline over every OTHER employee-day (own history + peers).
      final baseline = RobustBaseline.fromSamples(
        [...allValues]..remove(value),
      );
      final baselineBreach = baseline.isAnomalous(
        value,
        k: FraudDefaults.baselineK,
        minSpread: FraudDefaults.baselineMinSpreadValue,
        minSamples: FraudDefaults.baselineMinSamples,
      );

      if (!countBreach && !valueBreach && !baselineBreach) continue;

      final relatedIds = await _refundIdsFor(ctx, user, day);
      drafts.add(FraudFlagDraft(
        ruleCode: code,
        severity: FraudSeverity.high,
        title: 'Unusual refund volume',
        description:
            '$cnt refund(s) totalling ₱${value.toStringAsFixed(2)} were '
            'processed by one employee on $day.',
        dedupeKey: '$code|$user|$day',
        detectedAt: DateTime.fromMillisecondsSinceEpoch(
          r.read<int>('last_at') * 1000,
        ),
        // Scope to a branch only when the day's refunds all sit in one;
        // a cross-branch day is business-wide by nature.
        branchId: r.read<int>('branch_cnt') == 1
            ? r.readNullable<String>('branch_one')
            : null,
        subjectUserId: user,
        evidence: [
          {'fact': 'Refund count', 'value': cnt, 'window': day},
          {
            'fact': 'Refund value',
            'value': value,
            'window': day,
            if (baseline.sampleCount >= FraudDefaults.baselineMinSamples)
              'baseline_median': baseline.median,
          },
          if (countBreach)
            {
              'fact': 'Above fixed daily count floor',
              'value': FraudDefaults.excessiveRefundCountPerDay,
            },
          if (valueBreach)
            {
              'fact': 'Above fixed daily value floor',
              'value': FraudDefaults.excessiveRefundValuePerDay,
            },
          if (baselineBreach)
            {
              'fact': 'Anomalous vs 30-day employee/peer baseline',
              'value':
                  'threshold ₱${baseline.thresholdFor(k: FraudDefaults.baselineK, minSpread: FraudDefaults.baselineMinSpreadValue).toStringAsFixed(2)}',
            },
        ],
        relatedIds: relatedIds,
      ));
    }
    return drafts;
  }

  Future<List<String>> _refundIdsFor(
    FraudScanContext ctx,
    String user,
    String day,
  ) async {
    final rows = await ctx.db
        .customSelect(
          'SELECT id FROM refunds '
          'WHERE business_id = ? AND refunded_by = ? '
          "AND DATE(created_at,'unixepoch','localtime') = ? "
          'AND deleted_at IS NULL LIMIT 20',
          variables: [
            Variable.withString(ctx.businessId),
            Variable.withString(user),
            Variable.withString(day),
          ],
        )
        .get();
    return [for (final r in rows) r.read<String>('id')];
  }
}
