import 'package:flutter/material.dart';

class FraudAlertsCard extends StatelessWidget {
  const FraudAlertsCard({super.key});

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
          // Header
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 20, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Fraud Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _AlertRow(
            title: 'Multiple refunds detected',
            subtitle: 'User: Sarah M.',
            severity: 'high',
          ),
          const SizedBox(height: 10),
          _AlertRow(
            title: 'Price override threshold exceeded',
            subtitle: 'User: Mike T.',
            severity: 'medium',
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                foregroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('View All Alerts', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String severity; // 'high' | 'medium' | 'low'

  const _AlertRow({
    required this.title,
    required this.subtitle,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            severity,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ),
      ],
    );
  }

  Color get _bgColor {
    switch (severity) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  Color get _textColor {
    switch (severity) {
      case 'high':
        return Colors.white;
      case 'medium':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF16A34A);
    }
  }
}
