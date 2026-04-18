import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

// ─── Shared white card shell ──────────────────────────────────────────────────

class ReportCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ReportCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: child,
    );
  }
}

// ─── Stat card (used by all 4 tabs) ──────────────────────────────────────────

class ReportStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? changeLabel;
  final bool? isPositive;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const ReportStatCard({
    super.key,
    required this.title,
    required this.value,
    this.changeLabel,
    this.isPositive,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (changeLabel != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  (isPositive ?? true)
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 15,
                  color: (isPositive ?? true)
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    changeLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: (isPositive ?? true)
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Stat cards row helper ────────────────────────────────────────────────────

/// Lays out [cards] in a responsive grid (1 row on wide, 2×2 on narrow).
class ReportStatCardsRow extends StatelessWidget {
  final List<Widget> cards;
  const ReportStatCardsRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      if (c.maxWidth > 800) {
        return Row(
          children: cards
              .map((w) => Expanded(child: w))
              .expand((w) => [w, const SizedBox(width: 12)])
              .toList()
            ..removeLast(),
        );
      }
      return Column(children: [
        Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ]),
      ]);
    });
  }
}

// ─── Shared formatters ────────────────────────────────────────────────────────

String fmtCurrency(double v) {
  if (v >= 1000000) return '₱${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(1)}k';
  return '₱${v.toStringAsFixed(0)}';
}

String fmtPct(double pct) {
  final sign = pct >= 0 ? '+' : '';
  return '$sign${pct.toStringAsFixed(1)}%';
}

double pctChange(double current, double prev) {
  if (prev == 0) return current > 0 ? 100 : 0;
  return (current - prev) / prev * 100;
}

double chartMaxY(List<double> values) {
  if (values.isEmpty) return 1000;
  final max = values.reduce((a, b) => a > b ? a : b);
  if (max == 0) return 1000;
  final step = (max / 4).ceilToDouble();
  final rounded = (step / 100).ceil() * 100.0;
  return rounded * 4;
}

String fmtAxisAmount(double v) {
  if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(1)}k';
  return '₱${v.toInt()}';
}
