import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/core/widgets/report_section.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

class ProfitSummaryTab extends StatelessWidget {
  final ReportsData data;
  const ProfitSummaryTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final chart = ProfitBarChart(trend: data.profitTrend);
    final table = _ProfitTrendTable(trend: data.profitTrend);
    // Desktop has the width to place the chart and breakdown side by side;
    // tablet and phone stack them so neither gets squeezed. Empty periods
    // render nothing in the table, so fall back to stacking to avoid a lone
    // half-width chart with dead space beside it.
    final hasRows = data.profitTrend.any((p) => p.label.isNotEmpty);
    final sideBySide = Breakpoints.isDesktop(context) && hasRows;

    // The KPI overview is rendered by the reports page above the filters.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sideBySide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: chart),
              const SizedBox(width: 16),
              Expanded(child: table),
            ],
          )
        else ...[
          chart,
          const SizedBox(height: 16),
          table,
        ],
      ],
    );
  }
}

// ─── Overview KPIs ────────────────────────────────────────────────────────────

/// The four headline stat cards for the Profit tab. Rendered by the reports
/// page at the top of the scroll body (above the filters), not inside the tab.
class ProfitOverviewCards extends StatelessWidget {
  final ReportsData data;
  const ProfitOverviewCards({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final netChange = pctChange(data.netProfit, data.prevNetProfit);

    return StatCardsRow(
      cards: [
        AppStatCard(
          title: 'Gross Revenue',
          value: fmtCurrency(data.grossRevenue),
          icon: IconlyBold.wallet,
          iconBg: AppColors.brandSoft,
          iconColor: AppColors.brand,
        ),
        AppStatCard(
          title: 'Cost of Goods',
          value: fmtCurrency(data.costOfGoods),
          icon: IconlyLight.category,
          iconBg: AppColors.errorSoft,
          iconColor: AppColors.error,
        ),
        AppStatCard(
          title: 'Operating Expenses',
          value: fmtCurrency(data.operatingExpenses),
          icon: IconlyLight.paper,
          iconBg: AppColors.warningSoft,
          iconColor: AppColors.warning,
        ),
        AppStatCard(
          title: 'Net Profit',
          value: fmtCurrency(data.netProfit),
          changeLabel:
              '${fmtPctChange(data.netProfit, data.prevNetProfit)} vs prev period',
          isPositive: netChange >= 0,
          icon: IconlyBold.activity,
          iconBg: AppColors.successSoft,
          iconColor: AppColors.success,
        ),
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
    return ReportSection(
      title: 'Revenue vs Expenses',
      icon: IconlyLight.chart,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          LegendDot(color: AppColors.brand, label: 'Revenue'),
          SizedBox(width: 12),
          LegendDot(color: AppColors.error, label: 'COGS'),
        ],
      ),
      child: trend.isEmpty ? _empty(context) : _buildChart(),
    );
  }

  Widget _empty(BuildContext context) => SizedBox(
    height: 220,
    child: Center(
      child: Text(
        'No data',
        style: AppTextStyles.body(context).copyWith(color: AppColors.textMuted),
      ),
    ),
  );

  Widget _buildChart() {
    final allValues = trend.expand((p) => [p.revenue, p.cogs]).toList();
    final maxY = chartMaxY(allValues);
    final interval = maxY / 4;

    return SizedBox(
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
                  if (idx < 0 || idx >= trend.length) return const SizedBox();
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
                const FlLine(color: AppColors.borderSoft, strokeWidth: 1),
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
    );
  }
}

// ─── Period breakdown table ───────────────────────────────────────────────────

class _ProfitTrendTable extends StatelessWidget {
  final List<ProfitTrendPoint> trend;
  const _ProfitTrendTable({required this.trend});

  static const _columns = [
    AppTableColumn(label: 'Period', flex: 3),
    AppTableColumn(label: 'Revenue', flex: 2, align: TextAlign.right),
    AppTableColumn(label: 'COGS', flex: 2, align: TextAlign.right),
    AppTableColumn(label: 'Net Profit', flex: 2, align: TextAlign.right),
    AppTableColumn(label: 'Margin', flex: 2, align: TextAlign.right),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = trend.where((p) => p.label.isNotEmpty).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    // Totals span every bucket; labels are blanked only for display, so sum
    // over the full trend to stay consistent with the KPI cards.
    double totRev = 0, totCogs = 0, totExp = 0;
    for (final p in trend) {
      totRev += p.revenue;
      totCogs += p.cogs;
      totExp += p.expenses;
    }
    final totNet = totRev - totCogs - totExp;
    final totMargin = totRev > 0
        ? '${(totNet / totRev * 100).toStringAsFixed(1)}%'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReportSectionHeading(
          title: 'Period Breakdown',
          icon: IconlyLight.paper,
        ),
        const SizedBox(height: 14),
        AppDataTable(
            columns: _columns,
            rowCount: rows.length,
            rowCellsBuilder: (ctx, i) {
              final p = rows[i];
              final net = p.revenue - p.cogs - p.expenses;
              final margin = p.revenue > 0
                  ? '${(net / p.revenue * 100).toStringAsFixed(1)}%'
                  : '—';
              final body = AppTextStyles.body(ctx);
              return [
                Text(p.label, style: body.copyWith(color: AppColors.textPrimary)),
                Text(
                  fmtCurrency(p.revenue),
                  style: body.copyWith(color: AppColors.textPrimary),
                ),
                Text(
                  fmtCurrency(p.cogs),
                  style: body.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  fmtCurrency(net),
                  style: body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: net >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  margin,
                  style: AppTextStyles.caption(ctx).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ];
            },
        ),
        const SizedBox(height: 10),
        _ProfitTotalsBar(
          revenue: totRev,
          cogs: totCogs,
          net: totNet,
          margin: totMargin,
        ),
      ],
    );
  }
}

class _ProfitTotalsBar extends StatelessWidget {
  final double revenue;
  final double cogs;
  final double net;
  final String margin;

  const _ProfitTotalsBar({
    required this.revenue,
    required this.cogs,
    required this.net,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final strong = AppTextStyles.body(context).copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
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
            flex: 3,
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
            child: Text(fmtCurrency(revenue), textAlign: TextAlign.right, style: strong),
          ),
          Expanded(
            flex: 2,
            child: Text(fmtCurrency(cogs), textAlign: TextAlign.right, style: strong),
          ),
          Expanded(
            flex: 2,
            child: Text(
              fmtCurrency(net),
              textAlign: TextAlign.right,
              style: strong.copyWith(
                color: net >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              margin,
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
          style: AppTextStyles.caption(context).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
