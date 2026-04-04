import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:pos/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:pos/features/inventory/presentation/widgets/inventory_desktop_table.dart';
import 'package:pos/features/inventory/presentation/widgets/inventory_mobile_card.dart';
import 'package:pos/features/inventory/presentation/widgets/inventory_stats_row.dart';
import 'package:pos/features/inventory/presentation/widgets/stock_adjustment_dialog.dart';

class Inventory extends StatefulWidget {
  const Inventory({super.key});

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  late final InventoryCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = InventoryCubit(sl());
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerLoad());
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  void _triggerLoad() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final branchId =
          context.read<BranchCubit>().getSelectedBranchIdForFiltering();
      _cubit.startWatching(
        businessId: authState.user.businessId ?? '',
        branchId: branchId,
      );
    }
  }

  Future<void> _onAdjust(InventoryItem item, bool isIncoming) async {
    final result = await showStockAdjustmentDialog(
      context: context,
      item: item,
      isIncoming: isIncoming,
    );
    if (result == null) return;

    await _cubit.adjustStock(
      variantId: item.variantId,
      productId: item.productId,
      isIncoming: result.isIncoming,
      quantity: result.quantity,
      reason: result.reason,
      note: result.note,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (_, curr) => curr is AuthAuthenticated,
            listener: (ctx, state) {
              if (state is AuthAuthenticated) {
                final branchId =
                    ctx.read<BranchCubit>().getSelectedBranchIdForFiltering();
                _cubit.startWatching(
                  businessId: state.user.businessId ?? '',
                  branchId: branchId,
                );
              }
            },
          ),
          BlocListener<BranchCubit, BranchState>(
            listenWhen: (prev, curr) =>
                prev.selectedBranchId != curr.selectedBranchId,
            listener: (ctx, branchState) {
              final authState = ctx.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                _cubit.startWatching(
                  businessId: authState.user.businessId ?? '',
                  branchId: branchState.selectedBranchId,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
            final data = state is InventoryLoaded
                ? state.data
                : InventoryData.empty;
            final items = state is InventoryLoaded
                ? state.displayItems
                : <InventoryItem>[];
            final isLoading = state is InventoryLoading;
            final selectedBranchId =
                state is InventoryLoaded ? state.selectedBranchId : null;
            final statusFilter =
                state is InventoryLoaded ? state.statusFilter : null;
            final viewMode = state is InventoryLoaded
                ? state.viewMode
                : InventoryViewMode.table;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: RefreshIndicator(
                onRefresh: () async => _triggerLoad(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final hPad = _adaptivePad(w);
                    // User toggle takes precedence; default to table on wide screens.
                    final useTable = viewMode == InventoryViewMode.table;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                          horizontal: hPad, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PageHeader(onRefresh: _triggerLoad),
                          const SizedBox(height: 18),

                          InventoryStatsRow(
                              data: data, isLoading: isLoading),
                          const SizedBox(height: 16),

                          _SearchAndFilter(
                            searchController: _searchController,
                            branches: data.branches,
                            selectedBranchId: selectedBranchId,
                            viewMode: viewMode,
                            onSearchChanged: (q) =>
                                _cubit.setSearchQuery(q),
                            onBranchChanged: (id) =>
                                _cubit.setBranchFilter(id),
                            onViewModeChanged: (m) =>
                                _cubit.setViewMode(m),
                          ),
                          const SizedBox(height: 12),

                          _StatusChips(
                            selected: statusFilter,
                            onSelected: (s) => _cubit.setStatusFilter(s),
                          ),
                          const SizedBox(height: 16),

                          if (isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(56),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (useTable)
                            InventoryDesktopTable(
                              items: items,
                              branches: data.branches,
                              onAdjust: _onAdjust,
                            )
                          else
                            _CardList(
                              items: items,
                              branches: data.branches,
                              onAdjust: _onAdjust,
                            ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Maps viewport width → horizontal padding.
/// 320 lp → 12 dp, 1200+ lp → 32 dp. Scales smoothly in between.
double _adaptivePad(double width) =>
    (12.0 + (width - 320).clamp(0.0, 880.0) / 880.0 * 20.0).clamp(12.0, 32.0);

// ── Page header ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  const _PageHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Levels',
                style: getOutfitStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Monitor and manage inventory across branches',
                style: getOutfitStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.borderSoft),
            foregroundColor: AppColors.textSecondary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

// ── Search + branch filter ───────────────────────────────────────────────────
// Uses DropdownButtonFormField (not DropdownMenu) so it fills its parent
// properly at every screen width without extra SizedBox hacks.

class _SearchAndFilter extends StatelessWidget {
  final TextEditingController searchController;
  final List<BranchInfo> branches;
  final String? selectedBranchId;
  final InventoryViewMode viewMode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onBranchChanged;
  final ValueChanged<InventoryViewMode> onViewModeChanged;

  const _SearchAndFilter({
    required this.searchController,
    required this.branches,
    required this.selectedBranchId,
    required this.viewMode,
    required this.onSearchChanged,
    required this.onBranchChanged,
    required this.onViewModeChanged,
  });

  InputDecoration get _base => InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      );

  @override
  Widget build(BuildContext context) {
    final searchField = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: _base.copyWith(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search, size: 18),
      ),
    );

    // Deduplicate by ID — duplicate branch rows crash DropdownButtonFormField
    final seenBranchIds = <String>{};
    final uniqueBranches =
        branches.where((b) => seenBranchIds.add(b.id)).toList();

    // Guard: if the current value is no longer in the list (e.g. after a sync
    // removed the branch), fall back to null so the assertion is never violated.
    final safeValue = uniqueBranches.any((b) => b.id == selectedBranchId)
        ? selectedBranchId
        : null;

    // Plain Container + DropdownButton — avoids InputDecorator's intrinsic-size
    // measurement loop that freezes the app, and avoids DropdownButtonFormField's
    // FormField state that won't update on rebuilds (causing the assertion crash).
    final branchDropdown = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(Icons.store_outlined,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: safeValue,
                isExpanded: true,
                isDense: true,
                style:
                    getOutfitStyle(fontSize: 14, color: AppColors.textPrimary),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Branches',
                        style: getOutfitStyle(
                            fontSize: 14, color: AppColors.textPrimary)),
                  ),
                  ...uniqueBranches.map(
                    (b) => DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(b.name,
                          style: getOutfitStyle(
                              fontSize: 14, color: AppColors.textPrimary)),
                    ),
                  ),
                ],
                onChanged: onBranchChanged,
              ),
            ),
          ),
        ],
      ),
    );

    final viewToggle = _ViewToggle(
      current: viewMode,
      onChanged: onViewModeChanged,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Side-by-side at ≥ 540 lp; stacked below that.
        if (constraints.maxWidth >= 540) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: searchField),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: branchDropdown),
              const SizedBox(width: 12),
              viewToggle,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: branchDropdown),
                const SizedBox(width: 10),
                viewToggle,
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── View mode toggle (Cards ↔ Table) ────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final InventoryViewMode current;
  final ValueChanged<InventoryViewMode> onChanged;

  const _ViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.grid_view_rounded,
            tooltip: 'Card view',
            active: current == InventoryViewMode.cards,
            isFirst: true,
            onTap: () => onChanged(InventoryViewMode.cards),
          ),
          Container(width: 1, height: 22, color: AppColors.borderSoft),
          _ToggleBtn(
            icon: Icons.table_rows_rounded,
            tooltip: 'Table view',
            active: current == InventoryViewMode.table,
            isFirst: false,
            onTap: () => onChanged(InventoryViewMode.table),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final bool isFirst;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(9) : Radius.zero,
          right: isFirst ? Radius.zero : const Radius.circular(9),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.brandSoft : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(9) : Radius.zero,
              right: isFirst ? Radius.zero : const Radius.circular(9),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? AppColors.brand : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Status filter chips ──────────────────────────────────────────────────────

class _StatusChips extends StatelessWidget {
  final StockStatus? selected;
  final ValueChanged<StockStatus?> onSelected;

  const _StatusChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final chips = <({String label, StockStatus? value})>[
      (label: 'All', value: null),
      (label: 'Low Stock', value: StockStatus.lowStock),
      (label: 'Warning', value: StockStatus.warning),
      (label: 'In Stock', value: StockStatus.inStock),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final isActive = selected == c.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(c.label),
              selected: isActive,
              onSelected: (_) => onSelected(isActive ? null : c.value),
              labelStyle: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.brand : AppColors.textSecondary,
              ),
              selectedColor: AppColors.brandSoft,
              checkmarkColor: AppColors.brand,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isActive ? AppColors.brand : AppColors.borderSoft,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Card list (mobile / narrow tablet) ──────────────────────────────────────
// Each InventoryItemCard uses its own LayoutBuilder to decide mobile vs
// horizontal layout — no isTablet flag needed here.

class _CardList extends StatelessWidget {
  final List<InventoryItem> items;
  final List<BranchInfo> branches;
  final void Function(InventoryItem, bool) onAdjust;

  const _CardList({
    required this.items,
    required this.branches,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 56),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No products found',
                style: getOutfitStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Add products to start tracking inventory',
                style:
                    getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: items
          .map((item) => InventoryItemCard(
                item: item,
                branches: branches,
                onAdjust: onAdjust,
              ))
          .toList(),
    );
  }
}
