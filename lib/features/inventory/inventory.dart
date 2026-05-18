import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';
import 'package:pos/core/widgets/branch_action_dialog.dart';
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
      final branchId = context
          .read<BranchCubit>()
          .getSelectedBranchIdForFiltering();
      _cubit.startWatching(
        businessId: authState.user.businessId ?? '',
        branchId: branchId,
      );
    }
  }

  Future<void> _onAdjust(InventoryItem item, bool isIncoming) async {
    final branchCubit = context.read<BranchCubit>();
    var selectedBranchId = branchCubit.state.selectedBranchId;
    if (selectedBranchId == null || selectedBranchId.trim().isEmpty) {
      final selection = await showBranchActionDialog(
        context,
        title: 'Select Branch',
        description:
            "You're currently viewing all branches. Choose where to adjust stock:",
        confirmPrefix: 'Use',
        emptyTitle: 'No branches available',
        emptyMessage: 'Please add a branch before adjusting stock.',
        selectLabel: 'Select a Branch',
      );

      if (selection == null || !mounted) return;

      await branchCubit.selectBranch(selection.name);
      selectedBranchId = selection.id;
      _cubit.setBranchFilter(selectedBranchId);
    }
    if (!mounted) return;
    final result = await showStockAdjustmentDialog(
      context: context,
      item: item,
      isIncoming: isIncoming,
    );
    if (result == null) return;

    await _cubit.adjustStock(
      variantId: item.variantId,
      productId: item.productId,
      productName: item.productName,
      variantName: item.variantName,
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
                final branchId = ctx
                    .read<BranchCubit>()
                    .getSelectedBranchIdForFiltering();
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
            final statusFilter = state is InventoryLoaded
                ? state.statusFilter
                : null;
            final viewMode = state is InventoryLoaded
                ? state.viewMode
                : AppViewMode.table;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final hPad = _adaptivePad(w);
                  final useTable = viewMode == AppViewMode.table;
                  final branches =
                      context.read<BranchCubit>().state.selectedBranchId == null
                      ? data.branches
                      : <BranchInfo>[];

                  final headerSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InventoryStatsRow(data: data, isLoading: isLoading),
                      const SizedBox(height: 16),
                      _SearchAndFilter(
                        searchController: _searchController,
                        viewMode: viewMode,
                        onSearchChanged: (q) => _cubit.setSearchQuery(q),
                        onViewModeChanged: (m) => _cubit.setViewMode(m),
                      ),
                      const SizedBox(height: 12),
                      _StatusChips(
                        selected: statusFilter,
                        onSelected: (s) => _cubit.setStatusFilter(s),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );

                  // Table mode: fixed header + Expanded table with its own
                  // vertical scroll. This avoids nesting the wide table inside
                  // an unbounded vertical SingleChildScrollView, which is what
                  // caused the overflow / layout crash on mobile.
                  if (useTable) {
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                          child: headerSection,
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
                            child: RefreshIndicator(
                              onRefresh: () async => _triggerLoad(),
                              child: isLoading
                                  ? const _InventorySkeleton()
                                  : InventoryDesktopTable(
                                      items: items,
                                      branches: branches,
                                      onAdjust: _onAdjust,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Card mode: normal full-page vertical scroll.
                  return RefreshIndicator(
                    onRefresh: () async => _triggerLoad(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerSection,
                          if (isLoading)
                            const _InventorySkeleton()
                          else
                            _CardList(
                              items: items,
                              branches: branches,
                              onAdjust: _onAdjust,
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

double _adaptivePad(double width) =>
    (12.0 + (width - 320).clamp(0.0, 880.0) / 880.0 * 20.0).clamp(12.0, 32.0);

// ── Page header ─────────────────────────────────────────────────────────────

class _SearchAndFilter extends StatelessWidget {
  final TextEditingController searchController;
  final AppViewMode viewMode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AppViewMode> onViewModeChanged;

  const _SearchAndFilter({
    required this.searchController,
    required this.viewMode,
    required this.onSearchChanged,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search, size: 18),
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
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        AppViewToggle(current: viewMode, onChanged: onViewModeChanged),
      ],
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
      (label: 'Not Tracked', value: StockStatus.notTracked),
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
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'No products found',
                style: getOutfitStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add products to start tracking inventory',
                style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => InventoryItemCard(
              item: item,
              branches: branches,
              onAdjust: onAdjust,
            ),
          )
          .toList(),
    );
  }
}

// ── Inventory skeleton loader ─────────────────────────────────────────────────

class _InventorySkeleton extends StatefulWidget {
  const _InventorySkeleton();

  @override
  State<_InventorySkeleton> createState() => _InventorySkeletonState();
}

class _InventorySkeletonState extends State<_InventorySkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final shimmerPos = -0.3 + 1.6 * _ctrl.value;

        Widget box({double? width, double height = 14, double radius = 8}) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                colors: const [
                  Color(0xFFE2E8F0),
                  Color(0xFFECF0F6),
                  Color(0xFFF5F8FC),
                  Color(0xFFECF0F6),
                  Color(0xFFE2E8F0),
                ],
                stops: [
                  (shimmerPos - 0.4).clamp(0.0, 1.0),
                  (shimmerPos - 0.2).clamp(0.0, 1.0),
                  shimmerPos.clamp(0.0, 1.0),
                  (shimmerPos + 0.2).clamp(0.0, 1.0),
                  (shimmerPos + 0.4).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        }

        Widget skRow() => Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        box(width: 160, height: 14),
                        const SizedBox(height: 5),
                        box(width: 100, height: 11, radius: 5),
                        const SizedBox(height: 4),
                        box(width: 72, height: 10, radius: 5),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  box(width: 72, height: 22, radius: 10),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  box(width: 70, height: 13, radius: 5),
                  const SizedBox(width: 16),
                  box(width: 70, height: 13, radius: 5),
                  const SizedBox(width: 16),
                  box(width: 70, height: 13, radius: 5),
                ],
              ),
            ],
          ),
        );

        return Column(children: List.generate(7, (_) => skRow()));
      },
    );
  }
}
