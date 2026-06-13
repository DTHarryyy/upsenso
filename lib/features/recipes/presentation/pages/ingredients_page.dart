import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_filter_chip.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/core/widgets/app_status_badge.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/recipes/domain/entities/ingredient.dart';
import 'package:pos/features/recipes/domain/repositories/i_ingredients_repository.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredients_cubit.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredients_state.dart';
import 'package:pos/features/recipes/presentation/pages/ingredient_detail_page.dart';
import 'package:pos/features/recipes/presentation/widgets/ingredient_form_sheet.dart';
import 'package:pos/features/recipes/presentation/widgets/ingredient_stock_sheet.dart';

class IngredientsPage extends StatelessWidget {
  const IngredientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => IngredientsCubit(
        repository: sl<IIngredientsRepository>(),
        businessId: authState.user.businessId ?? '',
      )..watch(),
      child: const _IngredientsView(),
    );
  }
}

class _IngredientsView extends StatelessWidget {
  const _IngredientsView();

  // Returns the branch ID to use for stock writes.
  // Falls back to selectedBranchId when filter is "All Branches".
  String? _resolveBranchId(BuildContext context) {
    final cubit = context.read<BranchCubit>();
    return cubit.getSelectedBranchIdForFiltering() ??
        cubit.state.selectedBranchId;
  }

  void _showForm(BuildContext context, {Ingredient? ingredient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<IngredientsCubit>(),
        child: IngredientFormSheet(
          ingredient: ingredient,
          branchId: _resolveBranchId(context),
        ),
      ),
    );
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
      await context.read<IngredientsCubit>().adjustStock(
        variantId: ingredient.id,
        productId: ingredient.productId,
        branchId: branchId,
        isIncoming: result.isIncoming,
        quantity: result.quantity,
        reason: result.reason,
        note: result.note,
      );
      if (context.mounted) {
        final verb = result.isIncoming ? 'added to' : 'removed from';
        AppToast.show(
          context,
          'Stock updated',
          subtitle:
              '${_fmt(result.quantity)} ${ingredient.unit ?? 'pcs'} $verb ${ingredient.name}.',
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, Ingredient ingredient) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete ingredient?',
          style: getOutfitStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '"${ingredient.name}" will be hidden from all recipes. '
          'Existing stock history is preserved.',
          style: getOutfitStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<IngredientsCubit>().delete(ingredient.productId);
        if (context.mounted) {
          AppToast.show(context, '${ingredient.name} deleted');
        }
      }
    });
  }

  void _openDetail(BuildContext context, Ingredient ingredient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IngredientDetailPage(
          ingredient: ingredient,
          businessId: context.read<IngredientsCubit>().businessId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IngredientsCubit, IngredientsState>(
      listenWhen: (_, s) => s is IngredientsError,
      listener: (context, state) {
        if (state is IngredientsError) {
          AppToast.show(context, state.message, variant: AppToastVariant.error);
        }
      },
      builder: (context, state) {
        final loaded = state is IngredientsLoaded ? state : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppSubPageBar(title: 'Ingredients'),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showForm(context),
            backgroundColor: AppColors.brand,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Add',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: AppSearchBar(
                  hint: 'Search ingredients...',
                  onChanged: (q) => context.read<IngredientsCubit>().search(q),
                ),
              ),
              if (loaded != null) ...[
                const SizedBox(height: 8),
                _FilterRow(loaded: loaded),
              ],
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, IngredientsState state) {
    if (state is IngredientsLoading || state is IngredientsInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }
    if (state is IngredientsError) {
      return Center(
        child: Text(
          state.message,
          style: getOutfitStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    final items = state is IngredientsLoaded
        ? state.filtered
        : (state is IngredientsActionInProgress ? state.ingredients : []);

    final filter = state is IngredientsLoaded
        ? state.stockFilter
        : IngredientStockFilter.all;

    if (items.isEmpty) {
      return _EmptyState(filter: filter);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _IngredientTile(
        ingredient: items[index],
        onTap: () => _openDetail(context, items[index]),
        onEdit: () => _showForm(context, ingredient: items[index]),
        onDelete: () => _confirmDelete(context, items[index]),
        onRestock: () =>
            _handleStockAction(context, items[index], restockMode: true),
        onAdjust: () =>
            _handleStockAction(context, items[index], restockMode: false),
      ),
    );
  }
}

String _fmt(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final IngredientsLoaded loaded;
  const _FilterRow({required this.loaded});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IngredientsCubit>();
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          AppFilterChip(
            label: 'All',
            isSelected: loaded.stockFilter == IngredientStockFilter.all,
            onTap: () => cubit.setFilter(IngredientStockFilter.all),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Low Stock',
            isSelected: loaded.stockFilter == IngredientStockFilter.lowStock,
            badgeCount: loaded.lowStockCount,
            badgeColor: AppColors.warningSoft,
            onTap: () => cubit.setFilter(IngredientStockFilter.lowStock),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Out of Stock',
            isSelected: loaded.stockFilter == IngredientStockFilter.outOfStock,
            badgeCount: loaded.outOfStockCount,
            badgeColor: AppColors.errorSoft,
            onTap: () => cubit.setFilter(IngredientStockFilter.outOfStock),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IngredientStockFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (filter) {
      IngredientStockFilter.lowStock => (
        Icons.check_circle_outline_rounded,
        'All stocked up',
        'Nothing is running low right now.',
      ),
      IngredientStockFilter.outOfStock => (
        Icons.inventory_2_outlined,
        'Nothing out of stock',
        'Every ingredient has stock on hand.',
      ),
      IngredientStockFilter.all => (
        IconlyLight.category,
        'No ingredients yet',
        'Tap + to add your first ingredient.',
      ),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            style: getOutfitStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Ingredient tile ───────────────────────────────────────────────────────────

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestock;
  final VoidCallback onAdjust;

  const _IngredientTile({
    required this.ingredient,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onRestock,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    // Swipe right = Restock, swipe left = Adjust. We never actually dismiss —
    // confirmDismiss fires the action and returns false to keep the tile.
    return Dismissible(
      key: ValueKey(ingredient.id),
      background: _SwipeBg(
        color: AppColors.success,
        icon: Icons.add_circle_outline_rounded,
        label: 'Restock',
        alignLeft: true,
      ),
      secondaryBackground: _SwipeBg(
        color: AppColors.warning,
        icon: Icons.tune_rounded,
        label: 'Adjust',
        alignLeft: false,
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onRestock();
        } else {
          onAdjust();
        }
        return false;
      },
      child: _TileBody(
        ingredient: ingredient,
        onTap: onTap,
        onEdit: onEdit,
        onDelete: onDelete,
        onRestock: onRestock,
        onAdjust: onAdjust,
      ),
    );
  }
}

class _TileBody extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestock;
  final VoidCallback onAdjust;

  const _TileBody({
    required this.ingredient,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onRestock,
    required this.onAdjust,
  });

  ({String label, Color color}) _status() {
    if (ingredient.stock <= 0) {
      return (label: 'Out of Stock', color: AppColors.outOfStock);
    }
    if (ingredient.lowStockAlert != null &&
        ingredient.stock <= ingredient.lowStockAlert!) {
      return (label: 'Low Stock', color: AppColors.lowStock);
    }
    return (label: 'In Stock', color: AppColors.inStock);
  }

  @override
  Widget build(BuildContext context) {
    final unit = ingredient.unit ?? 'pcs';
    final stockLabel = _fmt(ingredient.stock);
    final status = _status();

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                IconlyLight.category,
                size: 20,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1 — name + stock value
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          ingredient.name,
                          style: getOutfitStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stockLabel,
                        style: getOutfitStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: status.color,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        unit,
                        style: getOutfitStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Line 2 — status badge + minimum
                  Row(
                    children: [
                      AppStatusBadge(label: status.label, color: status.color),
                      const Spacer(),
                      if (ingredient.lowStockAlert != null)
                        Text(
                          'Min ${ingredient.lowStockAlert} $unit',
                          style: getOutfitStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _TileMenu(
              onRestock: onRestock,
              onAdjust: onAdjust,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileMenu extends StatelessWidget {
  final VoidCallback onRestock;
  final VoidCallback onAdjust;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TileMenu({
    required this.onRestock,
    required this.onAdjust,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        switch (v) {
          case 'restock':
            onRestock();
          case 'adjust':
            onAdjust();
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (_) => [
        _menuItem('restock', Icons.add_circle_outline_rounded, 'Restock'),
        _menuItem('adjust', Icons.tune_rounded, 'Adjust Stock'),
        _menuItem('edit', IconlyLight.edit, 'Edit'),
        const PopupMenuDivider(height: 1),
        _menuItem('delete', IconlyLight.delete, 'Delete', destructive: true),
      ],
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  // One neutral row; only the destructive action carries an accent.
  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    bool destructive = false,
  }) {
    final iconColor = destructive ? AppColors.error : AppColors.textSecondary;
    final textColor = destructive ? AppColors.error : AppColors.textPrimary;
    return PopupMenuItem(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Text(label, style: getOutfitStyle(fontSize: 13.5, color: textColor)),
        ],
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final bool alignLeft;

  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
