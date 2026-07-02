import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/dashboard_card.dart';
import 'package:pos/features/insights/domain/insight.dart';
import 'package:pos/features/insights/presentation/cubit/insights_cubit.dart';
import 'package:pos/features/insights/presentation/cubit/insights_state.dart';

/// Dashboard "AI Insights" card (M2). Shows a short, ordered list of
/// plain-language insights generated on-device. Self-hiding: takes no space
/// while loading, when the user lacks `insights.view`, or when there is nothing
/// to report — so it can be dropped onto any dashboard unconditionally.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsightsCubit, InsightsState>(
      builder: (context, state) {
        final Widget child;
        if (state is InsightsError) {
          child = const _InsightsErrorCard();
        } else if (state is InsightsLoaded && !state.isEmpty) {
          child = _InsightsBody(insights: state.insights);
        } else {
          // Initial, loading, denied, or nothing to report → take no space.
          return const SizedBox.shrink();
        }
        // Own its bottom gap only when visible, so the surrounding dashboard
        // rhythm stays right whether or not the card renders.
        return Padding(padding: const EdgeInsets.only(bottom: 16), child: child);
      },
    );
  }
}

class _InsightsBody extends StatelessWidget {
  final List<Insight> insights;
  const _InsightsBody({required this.insights});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DashboardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Insights',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'On-device',
                style: textTheme.labelSmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < insights.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _InsightTile(insight: insights[i]),
          ],
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
    final accent = _accentColor(insight.severity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_categoryIcon(insight.category), size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight.message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  static Color _accentColor(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.critical:
        return AppColors.error;
      case InsightSeverity.attention:
        return AppColors.warning;
      case InsightSeverity.positive:
        return AppColors.success;
      case InsightSeverity.neutral:
        return AppColors.info;
    }
  }

  static IconData _categoryIcon(InsightCategory category) {
    switch (category) {
      case InsightCategory.sales:
        return Icons.trending_up;
      case InsightCategory.expenses:
        return Icons.account_balance_wallet_outlined;
      case InsightCategory.margin:
        return Icons.percent;
      case InsightCategory.inventory:
        return Icons.inventory_2_outlined;
    }
  }
}

/// Graceful, low-emphasis fallback when insight generation failed — keeps the
/// dashboard usable rather than showing a raw error or a blank.
class _InsightsErrorCard extends StatelessWidget {
  const _InsightsErrorCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DashboardCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_outlined,
              size: 20, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Insights aren't available right now.",
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
