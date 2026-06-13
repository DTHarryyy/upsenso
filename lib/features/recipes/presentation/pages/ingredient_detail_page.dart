import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/features/recipes/domain/entities/ingredient.dart';
import 'package:pos/features/recipes/domain/entities/stock_movement.dart';
import 'package:pos/features/recipes/domain/repositories/i_ingredients_repository.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredient_detail_cubit.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredient_detail_state.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredients_cubit.dart';
import 'package:pos/features/recipes/presentation/widgets/ingredient_form_sheet.dart';
import 'package:pos/features/recipes/presentation/widgets/ingredient_quick_actions.dart';
import 'package:pos/features/recipes/presentation/widgets/ingredient_stock_sheet.dart';
import 'package:pos/features/recipes/presentation/widgets/recent_activity_section.dart';
import 'package:pos/features/recipes/presentation/widgets/stock_hero_card.dart';

class IngredientDetailPage extends StatelessWidget {
  final Ingredient ingredient;
  final String businessId;

  const IngredientDetailPage({
    super.key,
    required this.ingredient,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IngredientDetailCubit(
        repository: sl<IIngredientsRepository>(),
        businessId: businessId,
        initialIngredient: ingredient,
      )..startWatching(),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  String? _resolveBranchId(BuildContext context) {
    final cubit = context.read<BranchCubit>();
    return cubit.getSelectedBranchIdForFiltering() ??
        cubit.state.selectedBranchId;
  }

  Future<void> _handleStockAction(
    BuildContext context,
    Ingredient ingredient, {
    required bool restockMode,
  }) async {
    final branchId = _resolveBranchId(context);
    if (branchId == null) {
      AppToast.show(
        context,
        'No branch selected',
        subtitle: 'Pick a specific branch before changing stock.',
        variant: AppToastVariant.warning,
      );
      return;
    }

    final result = await showIngredientStockSheet(
      context: context,
      ingredient: ingredient,
      restockMode: restockMode,
    );

    if (result != null && context.mounted) {
      await context.read<IngredientDetailCubit>().adjustStock(
        branchId: branchId,
        isIncoming: result.isIncoming,
        quantity: result.quantity,
        reason: result.reason,
        note: result.note,
      );
      if (context.mounted) {
        AppToast.show(context, 'Stock updated');
      }
    }
  }

  void _openEditSheet(BuildContext context, Ingredient ingredient) {
    final branchId = _resolveBranchId(context);
    final businessId = context.read<IngredientDetailCubit>().businessId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        // Scoped cubit — only needs update(), no watch() call required.
        create: (_) => IngredientsCubit(
          repository: sl<IIngredientsRepository>(),
          businessId: businessId,
        ),
        child: IngredientFormSheet(ingredient: ingredient, branchId: branchId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IngredientDetailCubit, IngredientDetailState>(
      listenWhen: (_, s) => s is IngredientDetailError,
      listener: (context, state) {
        if (state is IngredientDetailError) {
          AppToast.show(context, state.message, variant: AppToastVariant.error);
        }
      },
      builder: (context, state) {
        final ingredient = state is IngredientDetailLoaded
            ? state.ingredient
            : null;
        final history = state is IngredientDetailLoaded
            ? state.history
            : <StockMovement>[];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            title: Text(
              ingredient?.name ?? 'Ingredient',
              style: getOutfitStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              if (ingredient != null)
                IconButton(
                  onPressed: () => _openEditSheet(context, ingredient),
                  icon: const Icon(
                    IconlyLight.edit,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Edit',
                ),
            ],
          ),
          body: state is IngredientDetailLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.brand),
                )
              : ingredient == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StockHeroCard(ingredient: ingredient),
                      const SizedBox(height: 10),
                      IngredientQuickActions(
                        onRestock: () => _handleStockAction(
                          context,
                          ingredient,
                          restockMode: true,
                        ),
                        onAdjust: () => _handleStockAction(
                          context,
                          ingredient,
                          restockMode: false,
                        ),
                      ),
                      const SizedBox(height: 14),
                      RecentActivitySection(
                        history: history,
                        unit: ingredient.unit ?? 'pcs',
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
