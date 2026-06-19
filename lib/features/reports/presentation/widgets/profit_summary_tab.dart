import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

class ProfitSummaryTab extends StatelessWidget {
  final ReportsData data;
  const ProfitSummaryTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfitBarChart(trend: data.profitTrend),
        const SizedBox(height: 16),
        _ProfitTrendTable(trend: data.profitTrend),
      ],
    );
  }
}

// ─── Revenue vs COGS bar chart ────────────────────────────────────────────────

class ProfitBarChart extends StatelessWidget {
  final List<ProfitTrendPoint> trend;
  const ProfitBarChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const ReportCard(
        child: SizedBox(
          height: 260,
          child: Center(
            child: Text(
              'No data',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    final allValues = trend.expand((p) => [p.revenue, p.cogs]).toList();
    final maxY = chartMaxY(allValues);
    final interval = maxY / 4;

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Revenue vs Expenses',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              LegendDot(color: AppColors.brand, label: 'Revenue'),
              const SizedBox(width: 12),
              LegendDot(color: AppColors.error, label: 'COGS'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, rodIndex) {
                      final label = trend[group.x].label.isNotEmpty
                          ? trend[group.x].label
                          : '${group.x + 1}';
                      final name = rodIndex == 0 ? 'Revenue' : 'COGS';
                      return BarTooltipItem(
                        '$label\n$name: ${fmtCurrency(rod.toY)}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: interval,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          fmtAxisAmount(v),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= trend.length) {
                          return const SizedBox();
                        }
                        final label = trend[idx].label;
                        if (label.isEmpty) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.borderSoft, strokeWidth: 1),
                ),
                barGroups: List.generate(trend.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: trend[i].revenue,
                        color: AppColors.brand,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: trend[i].cogs,
                        color: AppColors.error,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: Duration.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Period breakdown table ───────────────────────────────────────────────────

class _ProfitTrendTable extends StatelessWidget {
  final List<ProfitTrendPoint> trend;
  const _ProfitTrendTable({required this.trend});

  @override
  Widget build(BuildContext context) {
    final rows = trend.where((p) => p.label.isNotEmpty).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    // Totals span every bucket; labels are blanked only for display, so sum
    // over the full trend to stay consistent with the KPI cards.
    double totRev = 0, totCogs = 0;
    for (final p in trend) {
      totRev += p.revenue;
      totCogs += p.cogs;
    }
    final totNet = totRev - totCogs;
    final totMargin = totRev > 0
        ? '${(totNet / totRev * 100).toStringAsFixed(1)}%'
        : '—';

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Period Breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          // Header
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: const _ProfitTableHeader(),
          ),
          const SizedBox(height: 2),
          // Rows
          ...List.generate(rows.length, (i) {
            final p = rows[i];
            final net = p.revenue - p.cogs;
            final margin = p.revenue > 0
                ? '${(net / p.revenue * 100).toStringAsFixed(1)}%'
                : '—';
            return Container(
              color: i.isOdd ? const Color(0xFFF7F9FC) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      p.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      fmtCurrency(p.revenue),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      fmtCurrency(p.cogs),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      fmtCurrency(net),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: net >= 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      margin,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
                  flex: 3,
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
                    fmtCurrency(totRev),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    fmtCurrency(totCogs),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    fmtCurrency(totNet),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: totNet >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    totMargin,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitTableHeader extends StatelessWidget {
  const _ProfitTableHeader();

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
        Expanded(flex: 3, child: Text('PERIOD', style: s)),
        Expanded(
          flex: 2,
          child: Text('REVENUE', style: s, textAlign: TextAlign.end),
        ),
        Expanded(
          flex: 2,
          child: Text('COGS', style: s, textAlign: TextAlign.end),
        ),
        Expanded(
          flex: 2,
          child: Text('NET PROFIT', style: s, textAlign: TextAlign.end),
        ),
        Expanded(
          flex: 2,
          child: Text('MARGIN', style: s, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

// ─── Legend dot ───────────────────────────────────────────────────────────────

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
