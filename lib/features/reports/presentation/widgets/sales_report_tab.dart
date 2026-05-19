import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

class SalesReportTab extends StatelessWidget {
  final ReportsData data;

  const SalesReportTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (_, c) {
            if (c.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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

// ─── Sales Trend line chart ───────────────────────────────────────────────────

class SalesTrendChart extends StatelessWidget {
  final List<SalesTrendPoint> trend;

  const SalesTrendChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return ReportCard(
        child: const SizedBox(
          height: 260,
          child: Center(
            child: Text(
              'No sales data',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    final totals = trend.map((p) => p.total).toList();
    final spots = List.generate(
      trend.length,
      (i) => FlSpot(i.toDouble(), totals[i]),
    );
    final maxY = chartMaxY(totals);
    final interval = maxY / 4;

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trend',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
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
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= trend.length) {
                          return const SizedBox();
                        }
                        final label = trend[idx].label;
                        if (label.isEmpty) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
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
          ),
        ],
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

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales by Category',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (stats.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No category data',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            Row(
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
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final total = stats.fold(0.0, (s, c) => s + c.total);

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
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
            child: const Row(
              children: [
                SizedBox(width: 14),
                Expanded(
                  flex: 5,
                  child: Text(
                    'CATEGORY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'REVENUE',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SHARE',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          ...List.generate(stats.length, (i) {
            final pct = total > 0 ? stats[i].total / total * 100 : 0.0;
            return Container(
              color: i.isOdd ? const Color(0xFFF7F9FC) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: _palette[i % _palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      stats[i].name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      fmtCurrency(stats[i].total),
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
                      '${pct.toStringAsFixed(1)}%',
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
          // Totals row
          Container(
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Expanded(
                  flex: 5,
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
                  flex: 3,
                  child: Text(
                    fmtCurrency(total),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    '100%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
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
