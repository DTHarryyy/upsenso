import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/app_skeleton.dart';

/// Placeholder ladder shown while the plan catalog is in flight.
///
/// Mirrors [PlanCard]'s box and the tab's responsive branch so the real cards
/// land in the space the placeholders already occupy — the alternative was a
/// one-line "Loading plans…" notice that then jumped into full-height cards.
///
/// [AppSkeletonList] can't serve here: it's an unshrunk `ListView`, and both
/// callers already render inside one.
class PlanCardsSkeleton extends StatelessWidget {
  final int count;

  const PlanCardsSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final lastIndex = count - 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Same breakpoint as the real ladder, or the layout would still jump.
        final wide = constraints.maxWidth >= 720 && count > 1;
        if (!wide) {
          return Column(
            children: [
              for (int i = 0; i < count; i++) ...[
                const _PlanCardSkeleton(),
                if (i != lastIndex) const SizedBox(height: 16),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < count; i++) ...[
              const Expanded(child: _PlanCardSkeleton()),
              if (i != lastIndex) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }
}

class _PlanCardSkeleton extends StatelessWidget {
  const _PlanCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Matches the badge gutter every real card reserves.
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSoft),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        child: Column(
          children: [
            const AppSkeleton(width: 90, height: 16),
            const SizedBox(height: 12),
            const AppSkeleton(width: 140, height: 38, radius: 10),
            const SizedBox(height: 6),
            const AppSkeleton(width: 110, height: 12),
            const SizedBox(height: 10),
            const AppSkeleton(width: 170, height: 13),
            const SizedBox(height: 22),
            const SizedBox(
              width: double.infinity,
              child: AppSkeleton(height: 46, radius: 30),
            ),
            const SizedBox(height: 24),
            for (int i = 0; i < 4; i++) const _BenefitRowSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _BenefitRowSkeleton extends StatelessWidget {
  const _BenefitRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 18, height: 18, radius: 9),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(height: 14),
                SizedBox(height: 6),
                AppSkeleton(height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
