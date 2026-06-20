import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/core/widgets/app_empty_state.dart';
import 'package:pos/core/widgets/app_status_badge.dart';
import 'package:pos/core/widgets/report_section.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

class BranchComparisonTab extends StatelessWidget {
  final ReportsData data;
  const BranchComparisonTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BranchOverview(data: data),
        const SizedBox(height: 20),
        _BranchTableSection(stats: data.branchStats),
      ],
    );
  }
}

// ─── Overview KPIs ────────────────────────────────────────────────────────────

class _BranchOverview extends StatelessWidget {
  final ReportsData data;
  const _BranchOverview({required this.data});

  @override
  Widget build(BuildContext context) {
    final branchCount = data.branchStats.length;
    final totalBranchSales = data.branchStats.fold<double>(
      0,
      (s, b) => s + b.totalSales,
    );
    final topBranch = data.branchStats.where((b) => b.isTop).firstOrNull;

    return StatCardsRow(
      cards: [
        AppStatCard(
          title: 'Active Branches',
          value: '$branchCount',
          icon: IconlyBold.work,
          iconBg: AppColors.brandSoft,
          iconColor: AppColors.brand,
        ),
        AppStatCard(
          title: 'Combined Sales',
          value: fmtCurrency(totalBranchSales),
          icon: IconlyBold.wallet,
          iconBg: AppColors.successSoft,
          iconColor: AppColors.success,
        ),
        AppStatCard(
          title: 'Top Branch',
          value: topBranch?.name ?? '—',
          icon: IconlyBold.ticket_star,
          iconBg: AppColors.warningSoft,
          iconColor: AppColors.warning,
        ),
        AppStatCard(
          title: 'Avg. per Branch',
          value: branchCount > 0
              ? fmtCurrency(totalBranchSales / branchCount)
              : '—',
          icon: IconlyLight.swap,
          iconBg: AppColors.infoSoft,
          iconColor: AppColors.info,
        ),
      ],
    );
  }
}

// ─── Branch performance table ─────────────────────────────────────────────────

class _BranchTableSection extends StatelessWidget {
  final List<BranchReportStat> stats;
  const _BranchTableSection({required this.stats});

  static const _columns = [
    AppTableColumn(label: 'Branch', flex: 4),
    AppTableColumn(label: 'Total Sales', flex: 2, align: TextAlign.right),
    AppTableColumn(label: 'Transactions', flex: 2, align: TextAlign.center),
    AppTableColumn(label: 'Avg. Ticket', flex: 2, align: TextAlign.center),
    AppTableColumn(label: 'Vs Last Period', flex: 2, align: TextAlign.right),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReportSectionHeading(
          title: 'Branch Performance',
          icon: IconlyLight.work,
        ),
        const SizedBox(height: 14),
        if (stats.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: AppEmptyState(
              icon: IconlyLight.work,
              title: 'No branch data',
              message: 'There are no branch sales for this period yet.',
            ),
          )
        else ...[
          AppDataTable(
            columns: _columns,
            rowCount: stats.length,
            rowCellsBuilder: (ctx, i) => _cells(ctx, stats[i]),
          ),
          const SizedBox(height: 10),
          _BranchTotalsBar(stats: stats),
        ],
      ],
    );
  }

  List<Widget> _cells(BuildContext context, BranchReportStat stat) {
    final isPos = stat.vsLastPeriodPct >= 0;
    final body = AppTextStyles.body(context);
    return [
      Row(
        children: [
          _BranchAvatar(name: stat.name, isTop: stat.isTop),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stat.name,
              style: body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (stat.isTop) ...[
            const SizedBox(width: 6),
            const AppStatusBadge(label: 'Top', color: AppColors.success),
          ],
        ],
      ),
      Text(
        fmtCurrency(stat.totalSales),
        style: body.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      Text(
        '${stat.transactions}',
        style: body.copyWith(color: AppColors.textSecondary),
      ),
      Text(
        fmtCurrency(stat.avgTicket),
        style: body.copyWith(color: AppColors.textSecondary),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPos ? IconlyBold.arrow_up_2 : IconlyBold.arrow_down_2,
              size: 14,
              color: isPos ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 3),
            Text(
              fmtPct(stat.vsLastPeriodPct),
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: isPos ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _BranchAvatar extends StatelessWidget {
  final String name;
  final bool isTop;
  const _BranchAvatar({required this.name, required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isTop ? AppColors.brandSoft : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w700,
            color: isTop ? AppColors.brand : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }
}

class _BranchTotalsBar extends StatelessWidget {
  final List<BranchReportStat> stats;
  const _BranchTotalsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    double totalSales = 0;
    int totalTxns = 0;
    for (final s in stats) {
      totalSales += s.totalSales;
      totalTxns += s.transactions;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'TOTAL',
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              fmtCurrency(totalSales),
              textAlign: TextAlign.right,
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$totalTxns',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
        ],
      ),
    );
  }
}
