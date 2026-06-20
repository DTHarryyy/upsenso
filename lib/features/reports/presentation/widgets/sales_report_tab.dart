import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/core/widgets/report_section.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

class SalesReportTab extends StatelessWidget {
  final ReportsData data;

  const SalesReportTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SalesOverview(data: data),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (_, c) {
            if (c.maxWidth > 800) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SalesTrendChart(trend: data.salesTrend),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: CategoryDonutChart(stats: data.categoryBreakdown),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                SalesTrendChart(trend: data.salesTrend),
                const SizedBox(height: 16),
                CategoryDonutChart(stats: data.categoryBreakdown),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _CategoryTable(stats: data.categoryBreakdown),
      ],
    );
  }
}

// ─── Overview KPIs ────────────────────────────────────────────────────────────

class _SalesOverview extends StatelessWidget {
  final ReportsData data;
  const _SalesOverview({required this.data});

  @override
  Widget build(BuildContext context) {
    final revChange = pctChange(data.totalRevenue, data.prevTotalRevenue);
    final txnChange = data.totalTransactions - data.prevTotalTransactions;
    final avgChange = pctChange(data.avgTicket, data.prevAvgTicket);
    final itemsChange = data.itemsSold - data.prevItemsSold;

    return StatCardsRow(
      cards: [
        AppStatCard(
          title: 'Total Revenue',
          value: fmtCurrency(data.totalRevenue),
          changeLabel:
              '${fmtPctChange(data.totalRevenue, data.prevTotalRevenue)} vs prev period',
          isPositive: revChange >= 0,
          icon: IconlyBold.wallet,
          iconBg: AppColors.brandSoft,
          iconColor: AppColors.brand,
        ),
        AppStatCard(
          title: 'Transactions',
          value: '${data.totalTransactions}',
          changeLabel: '${txnChange >= 0 ? '+' : ''}$txnChange vs prev period',
          isPositive: txnChange >= 0,
          icon: IconlyBold.chart,
          iconBg: AppColors.infoSoft,
          iconColor: AppColors.info,
        ),
        AppStatCard(
          title: 'Avg. Ticket',
          value: fmtCurrency(data.avgTicket),
          changeLabel:
              '${fmtPctChange(data.avgTicket, data.prevAvgTicket)} vs prev period',
          isPositive: avgChange >= 0,
          icon: IconlyBold.activity,
          iconBg: AppColors.successSoft,
          iconColor: AppColors.success,
        ),
        AppStatCard(
          title: 'Items Sold',
          value: '${data.itemsSold}',
          changeLabel:
              '${itemsChange >= 0 ? '+' : ''}$itemsChange vs prev period',
          isPositive: itemsChange >= 0,
          icon: IconlyLight.category,
          iconBg: AppColors.warningSoft,
          iconColor: AppColors.warning,
        ),
      ],
    );
  }
}

// ─── Sales Trend line chart ───────────────────────────────────────────────────

class SalesTrendChart extends StatelessWidget {
  final List<SalesTrendPoint> trend;

  const SalesTrendChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    return ReportSection(
      title: 'Sales Trend',
      icon: IconlyLight.activity,
      subtitle: 'Revenue across the period',
      child: trend.isEmpty
          ? const _ChartEmpty(label: 'No sales data')
          : _buildChart(),
    );
  }

  Widget _buildChart() {
    final totals = trend.map((p) => p.total).toList();
    final spots = List.generate(
      trend.length,
      (i) => FlSpot(i.toDouble(), totals[i]),
    );
    final maxY = chartMaxY(totals);
    final interval = maxY / 4;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.borderSoft, strokeWidth: 1),
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
                reservedSize: 56,
                interval: interval,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(fmtAxisAmount(v), style: _axisStyle),
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
                    child: Text(label, style: _axisStyleSmall),
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
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
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
    );
  }
}

// ─── Category donut chart ─────────────────────────────────────────────────────

class CategoryDonutChart extends StatelessWidget {
  final List<CategoryStat> stats;
  static const _palette = AppColors.chartPalette;

  const CategoryDonutChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.fold(0.0, (s, c) => s + c.total);

    return ReportSection(
      title: 'Sales by Category',
      icon: IconlyLight.category,
      subtitle: 'Share of revenue',
      child: stats.isEmpty
          ? const _ChartEmpty(label: 'No category data', height: 160)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
                      sections: List.generate(stats.length, (i) {
                        final pct = total > 0
                            ? stats[i].total / total * 100
                            : 0.0;
                        return PieChartSectionData(
                          value: pct,
                          color: _palette[i % _palette.length],
                          radius: 32,
                          showTitle: false,
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
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
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${fmtCurrency(stats[i].total)} ($pct%)',
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
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
                ),
              ],
            ),
    );
  }
}

// ─── Category breakdown table ─────────────────────────────────────────────────

class _CategoryTable extends StatelessWidget {
  final List<CategoryStat> stats;
  static const _palette = AppColors.chartPalette;

  const _CategoryTable({required this.stats});

  static const _columns = [
    AppTableColumn(label: 'Category', flex: 5),
    AppTableColumn(label: 'Revenue', flex: 3, align: TextAlign.right),
    AppTableColumn(label: 'Share', flex: 2, align: TextAlign.right),
  ];

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final total = stats.fold(0.0, (s, c) => s + c.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReportSectionHeading(
          title: 'Category Breakdown',
          icon: IconlyLight.bag_2,
        ),
        const SizedBox(height: 14),
        AppDataTable(
            columns: _columns,
            rowCount: stats.length,
            rowCellsBuilder: (ctx, i) {
              final pct = total > 0 ? stats[i].total / total * 100 : 0.0;
              return [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _palette[i % _palette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        stats[i].name,
                        style: AppTextStyles.body(ctx).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  fmtCurrency(stats[i].total),
                  style: AppTextStyles.body(ctx).copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: AppTextStyles.caption(ctx).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ];
            },
        ),
        const SizedBox(height: 10),
        _TotalsBar(total: total),
      ],
    );
  }
}

// Brand-tinted totals strip shared with the table above.
class _TotalsBar extends StatelessWidget {
  final double total;
  const _TotalsBar({required this.total});

  @override
  Widget build(BuildContext context) {
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
            flex: 5,
            child: Text(
              'TOTAL',
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmtCurrency(total),
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
              '100%',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared chart helpers ─────────────────────────────────────────────────────

const _axisStyle = TextStyle(fontSize: 10, color: AppColors.textMuted);
const _axisStyleSmall = TextStyle(fontSize: 9, color: AppColors.textMuted);

class _ChartEmpty extends StatelessWidget {
  final String label;
  final double height;
  const _ChartEmpty({required this.label, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.body(context).copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
