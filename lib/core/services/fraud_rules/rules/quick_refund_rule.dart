import 'package:drift/drift.dart';

import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';

/// The classic till move: ring up a sale, customer leaves, refund it
/// minutes later and pocket the cash. Volume rules never see a single
/// instance — this one fires per occurrence when the refunder IS the
/// original cashier, boosted when the goods were not restocked (money out,
/// nothing back on the shelf).
class QuickRefundRule implements FraudRule {
  @override
  String get code => 'QUICK_REFUND';

  @override
  bool get requiresFullAuditMirror => false;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    final rows = await ctx.db
        .customSelect(
          'SELECT r.id AS refund_id, r.refunded_by, r.total_amount, '
          'r.created_at AS refund_at, r.branch_id, t.id AS tx_id, '
          't.created_at AS sale_at, '
          '(SELECT COUNT(*) FROM refund_items ri '
          ' WHERE ri.refund_id = r.id AND ri.restocked = 0) AS unrestocked '
          'FROM refunds r JOIN transactions t ON t.id = r.transaction_id '
          'WHERE r.business_id = ? AND r.created_at >= ? '
          'AND r.deleted_at IS NULL '
          'AND r.refunded_by = t.cashier_id '
          'AND (r.created_at - t.created_at) BETWEEN 0 AND ?',
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(ctx.windowStartUnix),
            Variable<int>(FraudDefaults.quickRefundSeconds),
          ],
        )
        .get();

    return [
      for (final r in rows)
        FraudFlagDraft(
          ruleCode: code,
          severity: r.read<int>('unrestocked') > 0
              ? FraudSeverity.high
              : FraudSeverity.medium,
          title: 'Sale refunded minutes later by the same employee',
          description:
              'A ₱${r.read<double>('total_amount').toStringAsFixed(2)} sale was '
              'refunded ${((r.read<int>('refund_at') - r.read<int>('sale_at')) / 60).round()} '
              'minute(s) after it was rung up, by the employee who made the sale.'
              '${r.read<int>('unrestocked') > 0 ? ' The refunded item(s) were NOT returned to stock.' : ''}',
          dedupeKey: '$code|${r.read<String>('refund_id')}',
          detectedAt: DateTime.fromMillisecondsSinceEpoch(
            r.read<int>('refund_at') * 1000,
          ),
          branchId: r.readNullable<String>('branch_id'),
          subjectUserId: r.read<String>('refunded_by'),
          evidence: [
            {
              'fact': 'Minutes between sale and refund',
              'value':
                  ((r.read<int>('refund_at') - r.read<int>('sale_at')) / 60)
                      .round(),
            },
            {'fact': 'Refund amount', 'value': r.read<double>('total_amount')},
            {
              'fact': 'Lines not restocked',
              'value': r.read<int>('unrestocked'),
            },
          ],
          relatedIds: [
            r.read<String>('refund_id'),
            r.read<String>('tx_id'),
          ],
        ),
    ];
  }
}
