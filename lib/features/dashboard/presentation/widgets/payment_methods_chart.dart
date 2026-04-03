import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PaymentMethodsChart extends StatelessWidget {
  const PaymentMethodsChart({super.key});

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
            'Payment Methods',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: 45,
                    color: const Color(0xFF3B5BDB),
                    radius: 35,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: 30,
                    color: const Color(0xFF22C55E),
                    radius: 35,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: 25,
                    color: const Color(0xFFF59E0B),
                    radius: 35,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: const Color(0xFF3B5BDB), label: 'Cash'),
              const SizedBox(width: 16),
              _LegendItem(color: const Color(0xFF22C55E), label: 'Card'),
              const SizedBox(width: 16),
              _LegendItem(color: const Color(0xFFF59E0B), label: 'E-Wallet'),
            ],
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
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
