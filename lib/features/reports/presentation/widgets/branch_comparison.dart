import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

class BranchComparisonTab extends StatelessWidget {
  final ReportsData data;
  const BranchComparisonTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Branch Performance',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (data.branchStats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No branch data for this period',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            LayoutBuilder(builder: (_, c) {
              final table = _BranchTable(stats: data.branchStats);
              if (c.maxWidth < 560) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: 560, child: table),
                );
              }
              return table;
            }),
        ],
      ),
    );
  }
}

// ─── Table ────────────────────────────────────────────────────────────────────

class _BranchTable extends StatelessWidget {
  final List<BranchReportStat> stats;
  const _BranchTable({required this.stats});

  @override
  Widget build(BuildContext context) {
    double totalSales = 0;
    int totalTxns = 0;
    for (final s in stats) {
      totalSales += s.totalSales;
      totalTxns += s.transactions;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: const _BranchTableHeader(),
        ),
        const SizedBox(height: 2),
        // Data rows
        ...List.generate(
          stats.length,
          (i) => _BranchRow(stat: stats[i], index: i),
        ),
        // Totals
        Container(
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            children: [
              const Expanded(
                flex: 4,
                child: Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  fmtCurrency(totalSales),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$totalTxns',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Expanded(flex: 2, child: SizedBox()),
              const Expanded(flex: 2, child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }
}

class _BranchTableHeader extends StatelessWidget {
  const _BranchTableHeader();

  @override
  Widget build(BuildContext context) {
    const s = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 0.3,
    );
    return const Row(
      children: [
        Expanded(flex: 4, child: Text('BRANCH', style: s)),
        Expanded(
            flex: 2,
            child: Text('TOTAL SALES', style: s, textAlign: TextAlign.end)),
        Expanded(
            flex: 2,
            child:
                Text('TRANSACTIONS', style: s, textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text('AVG. TICKET', style: s, textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child:
                Text('VS LAST PERIOD', style: s, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _BranchRow extends StatelessWidget {
  final BranchReportStat stat;
  final int index;
  const _BranchRow({required this.stat, required this.index});

  @override
  Widget build(BuildContext context) {
    final isPos = stat.vsLastPeriodPct >= 0;

    return Container(
      color: index.isOdd ? const Color(0xFFF7F9FC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      child: Row(
        children: [
          // Branch name + badge
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: stat.isTop
                        ? AppColors.brandSoft
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      _initials(stat.name),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: stat.isTop
                            ? AppColors.brand
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stat.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (stat.isTop) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Top',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Total Sales
          Expanded(
            flex: 2,
            child: Text(
              fmtCurrency(stat.totalSales),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Transactions
          Expanded(
            flex: 2,
            child: Text(
              '${stat.transactions}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          // Avg ticket
          Expanded(
            flex: 2,
            child: Text(
              fmtCurrency(stat.avgTicket),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          // vs Last Period
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  isPos
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: isPos ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 3),
                Text(
                  fmtPct(stat.vsLastPeriodPct),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPos ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final words =
        clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }
}
