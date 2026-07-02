import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/dashboard_card.dart';
import 'package:pos/features/insights/domain/insight.dart';
import 'package:pos/features/insights/presentation/cubit/insights_cubit.dart';
import 'package:pos/features/insights/presentation/cubit/insights_state.dart';

/// Dashboard "Business Insights" card (M2). Shows a short, ordered list of
/// plain-language insights generated on-device. Self-hiding: takes no space
/// while loading, when the user lacks `insights.view`, or when there is nothing
/// to report — so it can be dropped onto any dashboard unconditionally.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsightsCubit, InsightsState>(
      builder: (context, state) {
        if (state is InsightsError) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: _InsightsErrorCard(),
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

class _InsightsBody extends StatelessWidget {
  final List<Insight> insights;
  const _InsightsBody({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, size: 17, color: AppColors.brand),
              const SizedBox(width: 7),
              Text(
                'Business Insights',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Today',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(insights.length, (i) {
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: _InsightTile(insight: insights[i]),
            );
          }),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final Insight insight;
  const _InsightTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor(insight.severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        border: Border(left: BorderSide(color: accent, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              _categoryIcon(insight.category),
              size: 13,
              color: accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
                height: 1.45,
              ),
            ),
          ),
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

  static IconData _categoryIcon(InsightCategory category) => switch (category) {
        InsightCategory.sales => Icons.trending_up_rounded,
        InsightCategory.expenses => Icons.receipt_long_outlined,
        InsightCategory.margin => Icons.show_chart_rounded,
        InsightCategory.inventory => Icons.inventory_2_outlined,
      };
}

class _InsightsErrorCard extends StatelessWidget {
  const _InsightsErrorCard();

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
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
