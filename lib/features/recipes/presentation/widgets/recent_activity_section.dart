import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/features/recipes/domain/entities/stock_movement.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredient_detail_cubit.dart';
import 'package:pos/features/recipes/presentation/pages/ingredient_history_page.dart';
import 'package:pos/features/recipes/presentation/widgets/activity_timeline_row.dart';

/// Preview of the most recent stock movements. Shows up to [_previewLimit]
/// entries; when there are more, a "View all" link opens the full history page.
class RecentActivitySection extends StatelessWidget {
  final List<StockMovement> history;
  final String unit;

  const RecentActivitySection({
    super.key,
    required this.history,
    required this.unit,
  });

  static const _previewLimit = 10;

  void _openFullHistory(BuildContext context) {
    // Reuse the live detail cubit so the history page mirrors this screen.
    final cubit = context.read<IngredientDetailCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const IngredientHistoryPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return AppSectionCard(
        title: 'Recent Activity',
        icon: IconlyLight.activity,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'No stock movements yet',
                style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      );
    }

    final hasMore = history.length > _previewLimit;
    final preview = history.take(_previewLimit).toList();

    return AppSectionCard(
      title: 'Recent Activity',
      icon: IconlyLight.activity,
      trailing: hasMore
          ? GestureDetector(
              onTap: () => _openFullHistory(context),
              behavior: HitTestBehavior.opaque,
              child: Text(
                'View all',
                style: getOutfitStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            )
          : null,
      children: [
        ...preview.asMap().entries.map((e) {
          return ActivityTimelineRow(
            movement: e.value,
            unit: unit,
            isFirst: e.key == 0,
            isLast: e.key == preview.length - 1,
          );
        }),
      ],
    );
  }
}
