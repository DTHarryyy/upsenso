import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
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
          icon: IconlyBold.tick_square,
          iconColor: AppColors.success,
          iconBg: AppColors.successSoft,
        ),
        AppStatCard(
          title: 'Pending Approval',
          value: fmtCurrency(totalPending),
          changeLabel: '$pendingCount item${pendingCount == 1 ? '' : 's'} waiting',
          isPositive: false,
          icon: IconlyLight.time_circle,
          iconColor: AppColors.warning,
          iconBg: AppColors.warningSoft,
        ),
        AppStatCard(
          title: 'Expense Count',
          value: expenseCount.toString(),
          changeLabel: 'All time',
          isPositive: true,
          icon: IconlyLight.paper,
          iconColor: AppColors.brand,
          iconBg: AppColors.brandSoft,
        ),
      ],
    );
  }
}
