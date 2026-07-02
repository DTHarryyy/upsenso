import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/dashboard_card.dart';
import 'package:pos/features/insights/domain/insight.dart';
import 'package:pos/features/insights/presentation/cubit/insights_cubit.dart';
import 'package:pos/features/insights/presentation/cubit/insights_state.dart';

/// Dashboard "Business Insights" card (M2).
///
/// Self-hiding when the user lacks `insights.view`, when loading, or when
/// there is genuinely nothing to report — safe to drop onto any dashboard.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsightsCubit, InsightsState>(
      builder: (context, state) {
        if (state is InsightsError) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: _ErrorCard(),
          );
        }
        if (state is InsightsLoaded && !state.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _InsightsBody(insights: state.insights),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Card body ────────────────────────────────────────────────────────────────

class _InsightsBody extends StatelessWidget {
  final List<Insight> insights;
  const _InsightsBody({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = insights.length;

    return DashboardCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Business Insights',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              _CountBadge(count: count),
              const Spacer(),
              Text(
                'This week',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Divider ─────────────────────────────────────────────────────
          Divider(
            height: 16,
            thickness: 1,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),

          // ── Rows ────────────────────────────────────────────────────────
          ...List.generate(insights.length, (i) {
            return Column(
              children: [
                _InsightRow(insight: insights[i]),
                if (i < insights.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 48,
                    color: theme.dividerColor.withValues(alpha: 0.4),
                  ),
              ],
            );
          }),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Count badge ──────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count ${count == 1 ? 'insight' : 'insights'}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.brand,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── Individual insight row ────────────────────────────────────────────────────

class _InsightRow extends StatelessWidget {
  final Insight insight;
  const _InsightRow({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor(insight.severity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: icon in a tinted rounded box
          _IconBox(category: insight.category, accent: accent),
          const SizedBox(width: 12),

          // Center: label + message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.categoryLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Right: metric + subtext (when present)
          if (insight.metric != null) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  insight.metric!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                if (insight.metricSubtext != null)
                  Text(
                    insight.metricSubtext!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _accentColor(InsightSeverity severity) => switch (severity) {
        InsightSeverity.critical => AppColors.error,
        InsightSeverity.attention => AppColors.warning,
        InsightSeverity.positive => AppColors.success,
        InsightSeverity.neutral => AppColors.brand,
      };
}

// ── Icon box ─────────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final InsightCategory category;
  final Color accent;
  const _IconBox({required this.category, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_icon(category), size: 17, color: accent),
    );
  }

  static IconData _icon(InsightCategory category) => switch (category) {
        InsightCategory.sales => Icons.trending_up_rounded,
        InsightCategory.expenses => Icons.receipt_long_outlined,
        InsightCategory.margin => Icons.show_chart_rounded,
        InsightCategory.inventory => Icons.inventory_2_outlined,
      };
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.insights_outlined, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Insights unavailable right now.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
