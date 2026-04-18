import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

// ─── Profit Summary tab ───────────────────────────────────────────────────────

class ProfitSummaryTab extends StatelessWidget {
  final ReportsData data;
  final ReportPeriod period;
  const ProfitSummaryTab({super.key, required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    final netChange = pctChange(data.netProfit, data.prevNetProfit);

    return Column(
      children: [
        ReportStatCardsRow(
          cards: [
            ReportStatCard(
              title: 'Gross Revenue',
              value: fmtCurrency(data.grossRevenue),
              icon: Icons.attach_money_rounded,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
            ReportStatCard(
              title: 'Cost of Goods',
              value: fmtCurrency(data.costOfGoods),
              icon: Icons.inventory_2_outlined,
              iconBg: AppColors.errorSoft,
              iconColor: AppColors.error,
            ),
            ReportStatCard(
              title: 'Operating Expenses',
              value: '₱0',
              icon: Icons.receipt_long_outlined,
              iconBg: AppColors.warningSoft,
              iconColor: AppColors.warning,
            ),
            ReportStatCard(
              title: 'Net Profit',
              value: fmtCurrency(data.netProfit),
              changeLabel: '${fmtPct(netChange)} vs prev period',
              isPositive: netChange >= 0,
              icon: Icons.trending_up_rounded,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ProfitBarChart(trend: data.profitTrend),
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
            child: Text('No data', style: TextStyle(color: AppColors.textMuted)),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
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
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: interval,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          fmtAxisAmount(v),
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
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
                        if (idx < 0 || idx >= trend.length) return const SizedBox();
                        final label = trend[idx].label;
                        if (label.isEmpty) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
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
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                      BarChartRodData(
                        toY: trend[i].cogs,
                        color: AppColors.error,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
