import 'package:drift/drift.dart';

import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';

/// Per-transaction discount above the floor ratio. Evidence includes the
/// employee's 30-day discount rate so a one-off promo reads differently
/// from a habit.
class HighDiscountRule implements FraudRule {
  @override
  String get code => 'HIGH_DISCOUNT';

  @override
  bool get requiresFullAuditMirror => false;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    final rows = await ctx.db
        .customSelect(
          'SELECT id, cashier_id, branch_id, discount_amount, subtotal, '
          'created_at FROM transactions '
          'WHERE business_id = ? AND created_at >= ? '
          "AND status != 'voided' AND discount_amount > 0 AND subtotal > 0 "
          'AND (discount_amount * 1.0 / subtotal) > ?',
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(ctx.windowStartUnix),
            Variable<double>(FraudDefaults.highDiscountRatio),
          ],
        )
        .get();
    if (rows.isEmpty) return const [];

    // One aggregate pass: each cashier's 30-day discount rate for context.
    final thirtyDaysAgo =
        ctx.now.subtract(const Duration(days: 30)).toUtc().millisecondsSinceEpoch ~/
            1000;
    final rates = await ctx.db
        .customSelect(
          'SELECT cashier_id, SUM(discount_amount) * 1.0 / SUM(subtotal) AS rate '
          'FROM transactions '
          "WHERE business_id = ? AND created_at >= ? AND status != 'voided' "
          'AND subtotal > 0 '
          'GROUP BY cashier_id',
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(thirtyDaysAgo),
          ],
        )
        .get();
    final rateByUser = {
      for (final r in rates)
        r.read<String>('cashier_id'): r.readNullable<double>('rate') ?? 0.0,
    };

    return [
      for (final r in rows)
        FraudFlagDraft(
          ruleCode: code,
          severity: FraudSeverity.medium,
          title: 'Heavy discount on a sale',
          description:
              'A ${(100 * r.read<double>('discount_amount') / r.read<double>('subtotal')).toStringAsFixed(0)}% '
              'discount (₱${r.read<double>('discount_amount').toStringAsFixed(2)}) '
              'was applied to a single sale.',
          dedupeKey: '$code|${r.read<String>('id')}',
          detectedAt: DateTime.fromMillisecondsSinceEpoch(
            r.read<int>('created_at') * 1000,
          ),
          branchId: r.readNullable<String>('branch_id'),
          subjectUserId: r.read<String>('cashier_id'),
          evidence: [
            {
              'fact': 'Discount ratio',
              'value':
                  '${(100 * r.read<double>('discount_amount') / r.read<double>('subtotal')).toStringAsFixed(1)}%',
              'baseline':
                  'floor ${(100 * FraudDefaults.highDiscountRatio).toStringAsFixed(0)}%',
            },
            {
              'fact': "Employee's 30-day average discount rate",
              'value':
                  '${(100 * (rateByUser[r.read<String>('cashier_id')] ?? 0)).toStringAsFixed(1)}%',
            },
          ],
          relatedIds: [r.read<String>('id')],
        ),
    ];
  }
}
