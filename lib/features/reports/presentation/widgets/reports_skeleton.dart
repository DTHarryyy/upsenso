import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/stat_card.dart';

/// Which slice of the report skeleton to draw. The reports page pins the Sales
/// KPI row above the filters, so it needs the KPI and body shimmers separately;
/// other tabs still use the [full] layout.
enum ReportsSkeletonVariant { full, kpis, body }

/// Loading placeholder for chart/table tabs. Mirrors the real layout —
/// overview KPI row, a chart section, then a table section — so content
/// doesn't jump when data lands.
class ReportsTabSkeleton extends StatefulWidget {
  final ReportsSkeletonVariant variant;

  const ReportsTabSkeleton({
    super.key,
    this.variant = ReportsSkeletonVariant.full,
  });

  @override
  State<ReportsTabSkeleton> createState() => _ReportsTabSkeletonState();
}

class _ReportsTabSkeletonState extends State<ReportsTabSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = kpiColumnCount(constraints.maxWidth, 4);

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final pos = -0.3 + 1.6 * _ctrl.value;

            Widget box({double? width, double height = 14, double radius = 8}) {
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    colors: const [
                      Color(0xFFE2E8F0),
                      Color(0xFFECF0F6),
                      Color(0xFFF5F8FC),
                      Color(0xFFECF0F6),
                      Color(0xFFE2E8F0),
                    ],
                    stops: [
                      (pos - 0.4).clamp(0.0, 1.0),
                      (pos - 0.2).clamp(0.0, 1.0),
                      pos.clamp(0.0, 1.0),
                      (pos + 0.2).clamp(0.0, 1.0),
                      (pos + 0.4).clamp(0.0, 1.0),
                    ],
                  ),
                ),
              );
            }

            Widget card(Widget child, {EdgeInsets? padding}) => Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: child,
            );

            final kpiCards = List.generate(
              4,
              (_) => card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(width: 70, height: 11, radius: 5),
                    const SizedBox(height: 14),
                    box(width: 90, height: 22, radius: 6),
                  ],
                ),
              ),
            );

            // KPI grid that matches StatCardsRow's responsive behaviour.
            final kpiRows = <Widget>[];
            for (var i = 0; i < kpiCards.length; i += perRow) {
              if (i > 0) kpiRows.add(const SizedBox(height: 12));
              final slice = kpiCards.sublist(
                i,
                (i + perRow).clamp(0, kpiCards.length),
              );
              kpiRows.add(
                Row(
                  children: slice
                      .map((w) => Expanded(child: w))
                      .expand((w) => [w, const SizedBox(width: 12)])
                      .toList()
                    ..removeLast(),
                ),
              );
            }

            Widget dataRow() => Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Expanded(child: box(height: 13)),
                  const SizedBox(width: 12),
                  box(width: 64, height: 13, radius: 5),
                ],
              ),
            );

            final chartCard = card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(width: 140, height: 15),
                  const SizedBox(height: 18),
                  box(height: 200, radius: 10),
                ],
              ),
              padding: const EdgeInsets.all(18),
            );

            final tableCard = card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(width: 120, height: 15),
                  const SizedBox(height: 14),
                  ...List.generate(5, (_) => dataRow()),
                ],
              ),
              padding: const EdgeInsets.all(18),
            );

            final children = <Widget>[];
            if (widget.variant != ReportsSkeletonVariant.body) {
              // The leading title placeholder only belongs to the full layout;
              // the KPI-only slice is rendered flush above the filter row.
              if (widget.variant == ReportsSkeletonVariant.full) {
                children
                  ..add(box(width: 150, height: 16))
                  ..add(const SizedBox(height: 16));
              }
              children.addAll(kpiRows);
            }
            if (widget.variant != ReportsSkeletonVariant.kpis) {
              if (children.isNotEmpty) children.add(const SizedBox(height: 20));
              children
                ..add(chartCard)
                ..add(const SizedBox(height: 16))
                ..add(tableCard);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          },
        );
      },
    );
  }
}
