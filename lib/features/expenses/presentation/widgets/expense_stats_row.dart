import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

class ExpenseStatsRow extends StatelessWidget {
  final double totalApproved;
  final double totalPending;
  final int expenseCount;
  final int pendingCount;

  const ExpenseStatsRow({
    super.key,
    required this.totalApproved,
    required this.totalPending,
    required this.expenseCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return StatCardsRow(
      cards: [
        AppStatCard(
          title: 'Total Approved',
          value: fmtCurrency(totalApproved),
          changeLabel: 'This Month',
          isPositive: true,
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.success,
          iconBg: AppColors.successSoft,
        ),
        AppStatCard(
          title: 'Pending Approval',
          value: fmtCurrency(totalPending),
          changeLabel: '$pendingCount item${pendingCount == 1 ? '' : 's'} waiting',
          isPositive: false,
          icon: Icons.hourglass_top_rounded,
          iconColor: AppColors.warning,
          iconBg: AppColors.warningSoft,
        ),
        AppStatCard(
          title: 'Expense Count',
          value: expenseCount.toString(),
          changeLabel: 'All time',
          isPositive: true,
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.brand,
          iconBg: AppColors.brandSoft,
        ),
      ],
    );
  }
}
