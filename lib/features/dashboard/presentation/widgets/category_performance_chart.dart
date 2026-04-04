import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';

class CategoryPerformanceChart extends StatelessWidget {
  final List<CategoryStat> stats;
  const CategoryPerformanceChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Performance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          if (stats.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text('No category data yet',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final name = stats[group.x].name;
                        return BarTooltipItem(
                          '$name\n₱${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: _maxY / 4,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            _fmt(value),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= stats.length) {
                            return const SizedBox();
                          }
                          final name = stats[idx].name;
                          final short = name.length > 8
                              ? '${name.substring(0, 7)}…'
                              : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              short,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600),
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
                    horizontalInterval: _maxY / 4,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  barGroups: List.generate(
                    stats.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: stats[i].total,
                          color: const Color(0xFF3B82F6),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                ),
                duration: Duration.zero,
              ),
            ),
        ],
      ),
    );
  }

  double get _maxY {
    if (stats.isEmpty) return 1000;
    final max = stats.map((s) => s.total).reduce((a, b) => a > b ? a : b);
    if (max == 0) return 1000;
    final step = (max / 4).ceilToDouble();
    final rounded = (step / 100).ceil() * 100.0;
    return rounded * 4;
  }

  String _fmt(double v) {
    if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(1)}k';
    return '₱${v.toInt()}';
  }
}
