import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/recipes/domain/entities/stock_movement.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredient_detail_cubit.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredient_detail_state.dart';
import 'package:pos/features/recipes/presentation/widgets/activity_timeline_row.dart';

/// Full stock-movement history for a single ingredient. Reuses the detail
/// cubit (provided by the caller) so the list stays live without refetching.
class IngredientHistoryPage extends StatelessWidget {
  const IngredientHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IngredientDetailCubit, IngredientDetailState>(
      builder: (context, state) {
        final loaded =
            state is IngredientDetailLoaded ? state : null;
        final history = loaded?.history ?? const <StockMovement>[];
        final unit = loaded?.ingredient.unit ?? 'pcs';
        final name = loaded?.ingredient.name;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.textPrimary),
            ),
            title: Text(
              name == null ? 'Stock History' : '$name · History',
              style: getOutfitStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          body: history.isEmpty
              ? Center(
                  child: Text(
                    'No stock movements yet',
                    style:
                        getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  itemCount: history.length,
                  itemBuilder: (context, i) => ActivityTimelineRow(
                    movement: history[i],
                    unit: unit,
                    isFirst: i == 0,
                    isLast: i == history.length - 1,
                  ),
                ),
        );
      },
    );
  }
}
