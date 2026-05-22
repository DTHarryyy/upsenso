import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

class AuditLogEmptyState extends StatelessWidget {
  final bool hasFilters;
  const AuditLogEmptyState({super.key, required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters ? IconlyLight.filter : IconlyLight.activity,
            size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'No logs match the current filters.'
                : 'No audit logs yet.',
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: 6),
            Text(
              'Try adjusting or clearing the filters.',
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: AppColors.textMuted.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
