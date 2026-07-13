import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/dashboard/presentation/widgets/dashboard_empty_state.dart';

class SalesTrendChart extends StatefulWidget {
  final DashboardData data;
  const SalesTrendChart({super.key, required this.data});

  @override
  State<SalesTrendChart> createState() => _SalesTrendChartState();
}

class _SalesTrendChartState extends State<SalesTrendChart> {
  bool _is7Days = true;

  List<double> get _totals =>
      _is7Days ? widget.data.sevenDayTotals : widget.data.thirtyDayTotals;

  List<String> get _labels =>
      _is7Days ? widget.data.sevenDayLabels : widget.data.thirtyDayLabels;

  double get _maxY {
    if (_totals.isEmpty) return 1000;
    final max = _totals.reduce((a, b) => a > b ? a : b);
    if (max == 0) return 1000;
    // Round up to a nice number
    final step = (max / 4).ceilToDouble();
    final rounded = (step / 100).ceil() * 100.0;
    return rounded * 4;
  }

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      _totals.length,
      (i) => FlSpot(i.toDouble(), _totals[i]),
    );

    final maxY = _maxY;
    final interval = maxY / 4;
    final pad = Breakpoints.isPhone(context) ? 12.0 : 16.0;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Trend',
                style: AppTextStyles.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  _PeriodToggle(
                    label: '7 Days',
                    isSelected: _is7Days,
                    onTap: () => setState(() => _is7Days = true),
                  ),
                  const SizedBox(width: 4),
                  _PeriodToggle(
                    label: '30 Days',
                    isSelected: !_is7Days,
                    onTap: () => setState(() => _is7Days = false),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: _totals.isEmpty
                ? const DashboardEmptyState(
                    icon: IconlyLight.activity,
                    iconColor: Color(0xFF3B82F6),
                    iconBg: Color(0xFFEFF6FF),
                    title: 'No sales data yet',
                    subtitle: 'Complete your first sale\nto see trends here',
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: interval,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                        getDrawingVerticalLine: (_) =>
                            FlLine(color: Colors.grey.shade200, strokeWidth: 1),
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
                            getTitlesWidget: (value, _) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                _formatAmount(value),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _is7Days ? 1 : 5,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _labels.length) {
                                return const SizedBox();
                              }
                              final label = _labels[idx];
                              if (label.isEmpty) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (_totals.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFF3B82F6),
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, _, _) =>
                                FlDotCirclePainter(
                                  radius: 3.5,
                                  color: const Color(0xFF3B82F6),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.08),
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

  String _formatAmount(double value) {
    if (value >= 1000) {
      return '₱${(value / 1000).toStringAsFixed(1)}k';
    }
    return '₱${value.toInt()}';
  }
}

class _PeriodToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
