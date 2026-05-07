import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pos/features/dashboard/presentation/widgets/dashboard_empty_state.dart';

class PaymentMethodsChart extends StatelessWidget {
  final Map<String, double> breakdown;

  const PaymentMethodsChart({super.key, required this.breakdown});

  static const _colors = [
    Color(0xFF3B5BDB),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);

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
            'Payment Methods',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const SizedBox(
              height: 160,
              child: DashboardEmptyState(
                icon: Icons.donut_large_rounded,
                iconColor: Color(0xFF3B5BDB),
                iconBg: Color(0xFFEEF2FF),
                title: 'No payments yet',
                subtitle: 'Breakdown appears\nafter first sale',
              ),
            )
          else
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: List.generate(entries.length, (i) {
                    final pct = total > 0 ? entries[i].value / total * 100 : 0.0;
                    return PieChartSectionData(
                      value: pct,
                      color: _colors[i % _colors.length],
                      radius: 35,
                      showTitle: false,
                    );
                  }),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (entries.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: List.generate(entries.length, (i) {
                final pct = total > 0
                    ? (entries[i].value / total * 100).toStringAsFixed(0)
                    : '0';
                return _LegendItem(
                  color: _colors[i % _colors.length],
                  label: '${entries[i].key} $pct%',
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

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
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
