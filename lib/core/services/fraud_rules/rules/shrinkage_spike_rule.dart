import 'package:drift/drift.dart';

import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';
import 'package:pos/core/services/fraud_rules/robust_baseline.dart';

/// Cost-weighted stock written off as Adjustment/Damage, per branch per day.
/// Value-weighting matters: 50 damaged candies and one "damaged" phone are
/// very different events. Baseline over other branch-days catches the slow
/// bleed that never crosses the fixed floor.
class ShrinkageSpikeRule implements FraudRule {
  @override
  String get code => 'SHRINKAGE_SPIKE';

  @override
  bool get requiresFullAuditMirror => false;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    final baselineStart =
        ctx.now.subtract(const Duration(days: 30)).toUtc().millisecondsSinceEpoch ~/
            1000;

    final rows = await ctx.db
        .customSelect(
          'SELECT l.branch_id, '
          "DATE(l.created_at,'unixepoch','localtime') AS day, "
          'SUM(l.quantity * COALESCE(v.cost_price, 0)) AS value, '
          'SUM(l.quantity) AS qty, COUNT(*) AS cnt, '
          'MAX(l.created_at) AS last_at '
          'FROM stock_ledger l '
          'LEFT JOIN product_variants v ON v.id = l.variant_id '
          "WHERE l.business_id = ? AND l.change_type = 'OUT' "
          "AND l.reason IN ('Adjustment','Damage') AND l.created_at >= ? "
          'GROUP BY l.branch_id, day',
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(baselineStart),
          ],
        )
        .get();

    final windowStartDay = localDayString(ctx.windowStart);
    final allValues = [for (final r in rows) r.read<double>('value')];
    final drafts = <FraudFlagDraft>[];

    for (final r in rows) {
      final day = r.read<String>('day');
      if (day.compareTo(windowStartDay) < 0) continue;

      final value = r.read<double>('value');
      final floorBreach = value > FraudDefaults.shrinkageValuePerDay;
      final baseline = RobustBaseline.fromSamples([...allValues]..remove(value));
      final baselineBreach = baseline.isAnomalous(
        value,
        k: FraudDefaults.baselineK,
        minSpread: FraudDefaults.baselineMinSpreadValue,
        minSamples: FraudDefaults.baselineMinSamples,
      );
      if (!floorBreach && !baselineBreach) continue;

      final branchId = r.readNullable<String>('branch_id');
      drafts.add(FraudFlagDraft(
        ruleCode: code,
        severity: FraudSeverity.high,
        title: 'Unusual stock write-off value',
        description:
            '₱${value.toStringAsFixed(2)} of stock (at cost) was written off '
            'as adjustment/damage in one branch on $day '
            '(${r.read<double>('qty').toStringAsFixed(1)} unit(s) across '
            '${r.read<int>('cnt')} movement(s)).',
        // No single subject: the ledger has no user column — the linked
        // stockAdjusted audit entries carry who did each movement.
        dedupeKey: '$code|${branchId ?? 'none'}|$day',
        detectedAt: DateTime.fromMillisecondsSinceEpoch(
          r.read<int>('last_at') * 1000,
        ),
        branchId: branchId,
        evidence: [
          {'fact': 'Write-off value (at cost)', 'value': value, 'window': day},
          {'fact': 'Movements', 'value': r.read<int>('cnt')},
          if (floorBreach)
            {
              'fact': 'Above fixed daily floor',
              'value': FraudDefaults.shrinkageValuePerDay,
            },
          if (baselineBreach)
            {
              'fact': 'Anomalous vs 30-day branch baseline',
              'value':
                  'threshold ₱${baseline.thresholdFor(k: FraudDefaults.baselineK, minSpread: FraudDefaults.baselineMinSpreadValue).toStringAsFixed(2)}',
            },
        ],
        relatedIds: await _ledgerIdsFor(ctx, branchId, day),
      ));
    }
    return drafts;
  }

  Future<List<String>> _ledgerIdsFor(
    FraudScanContext ctx,
    String? branchId,
    String day,
  ) async {
    final rows = await ctx.db
        .customSelect(
          'SELECT id FROM stock_ledger '
          "WHERE business_id = ? AND change_type = 'OUT' "
          "AND reason IN ('Adjustment','Damage') "
          "AND DATE(created_at,'unixepoch','localtime') = ? "
          '${branchId != null ? 'AND branch_id = ?' : ''} LIMIT 20',
          variables: [
            Variable.withString(ctx.businessId),
            Variable.withString(day),
            if (branchId != null) Variable.withString(branchId),
          ],
        )
        .get();
    return [for (final r in rows) r.read<String>('id')];
  }
}
