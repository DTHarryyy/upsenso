import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

// ─── Sales Report tab ─────────────────────────────────────────────────────────

class SalesReportTab extends StatelessWidget {
  final ReportsData data;
  final ReportPeriod period;

  const SalesReportTab({super.key, required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    final revChange = pctChange(data.totalRevenue, data.prevTotalRevenue);
    final txnChange = data.totalTransactions - data.prevTotalTransactions;
    final avgChange = pctChange(data.avgTicket, data.prevAvgTicket);
    final itemsChange = data.itemsSold - data.prevItemsSold;

    return Column(
      children: [
        ReportStatCardsRow(
          cards: [
            ReportStatCard(
              title: 'Total Revenue',
              value: fmtCurrency(data.totalRevenue),
              changeLabel: '${fmtPct(revChange)} vs prev period',
              isPositive: revChange >= 0,
              icon: Icons.attach_money_rounded,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
            ReportStatCard(
              title: 'Transactions',
              value: '${data.totalTransactions}',
              changeLabel: '${txnChange >= 0 ? '+' : ''}$txnChange vs prev period',
              isPositive: txnChange >= 0,
              icon: Icons.bar_chart_rounded,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7C3AED),
            ),
            ReportStatCard(
              title: 'Avg. Ticket',
              value: fmtCurrency(data.avgTicket),
              changeLabel: '${fmtPct(avgChange)} vs prev period',
              isPositive: avgChange >= 0,
              icon: Icons.trending_up_rounded,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
            ReportStatCard(
              title: 'Items Sold',
              value: '${data.itemsSold}',
              changeLabel: '${itemsChange >= 0 ? '+' : ''}$itemsChange vs prev period',
              isPositive: itemsChange >= 0,
              icon: Icons.inventory_2_outlined,
              iconBg: AppColors.warningSoft,
              iconColor: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (_, c) {
          if (c.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: SalesTrendChart(trend: data.salesTrend, period: period)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: CategoryDonutChart(stats: data.categoryBreakdown)),
              ],
            );
          }
          return Column(children: [
            SalesTrendChart(trend: data.salesTrend, period: period),
            const SizedBox(height: 16),
            CategoryDonutChart(stats: data.categoryBreakdown),
          ]);
        }),
      ],
    );
  }
}

// ─── Sales Trend line chart ───────────────────────────────────────────────────

class SalesTrendChart extends StatelessWidget {
  final List<SalesTrendPoint> trend;
  final ReportPeriod period;

  const SalesTrendChart({super.key, required this.trend, required this.period});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return ReportCard(
        child: const SizedBox(
          height: 260,
          child: Center(
            child: Text('No sales data', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    final totals = trend.map((p) => p.total).toList();
    final spots = List.generate(trend.length, (i) => FlSpot(i.toDouble(), totals[i]));
    final maxY = chartMaxY(totals);
    final interval = maxY / 4;

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trend',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.borderSoft, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
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
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= trend.length) return const SizedBox();
                        final label = trend[idx].label;
                        if (label.isEmpty) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
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
                minX: 0,
                maxX: (trend.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.brand,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.brand,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.brand.withAlpha(18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sales by Category donut chart ───────────────────────────────────────────

class CategoryDonutChart extends StatelessWidget {
  final List<CategoryStat> stats;

  static const _palette = AppColors.chartPalette;

  const CategoryDonutChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.fold(0.0, (s, c) => s + c.total);

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales by Category',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          if (stats.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text('No category data', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            LayoutBuilder(builder: (_, c) {
              final chart = SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 38,
                    sections: List.generate(stats.length, (i) {
                      final pct = total > 0 ? stats[i].total / total * 100 : 0.0;
                      return PieChartSectionData(
                        value: pct,
                        color: _palette[i % _palette.length],
                        radius: 32,
                        showTitle: false,
                      );
                    }),
                  ),
                ),
              );
              final legend = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(stats.length.clamp(0, 6), (i) {
                    final pct = total > 0
                        ? (stats[i].total / total * 100).toStringAsFixed(0)
                        : '0';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _palette[i % _palette.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stats[i].name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${fmtCurrency(stats[i].total)} ($pct%)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  chart,
                  const SizedBox(width: 16),
                  legend,
                ],
              );
            }),
        ],
      ),
    );
  }
}
