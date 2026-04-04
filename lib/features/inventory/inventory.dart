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

            return Scaffold(
              backgroundColor: AppColors.background,
              body: RefreshIndicator(
                onRefresh: () async => _triggerLoad(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Page header ──
                      _PageHeader(onRefresh: _triggerLoad),
                      const SizedBox(height: 16),

                      // ── Stat cards ──
                      InventoryStatsRow(data: data, isLoading: isLoading),
                      const SizedBox(height: 16),

                      // ── Search + branch filter ──
                      _SearchAndFilter(
                        searchController: _searchController,
                        branches: data.branches,
                        selectedBranchId: selectedBranchId,
                        onSearchChanged: (q) => _cubit.setSearchQuery(q),
                        onBranchChanged: (id) => _cubit.setBranchFilter(id),
                      ),
                      const SizedBox(height: 12),

                      // ── Status filter chips ──
                      _StatusChips(
                        selected: statusFilter,
                        onSelected: (s) => _cubit.setStatusFilter(s),
                      ),
                      const SizedBox(height: 16),

                      // ── Responsive table / cards ──
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 1024) {
                              return InventoryDesktopTable(
                                items: items,
                                branches: data.branches,
                                onAdjust: _onAdjust,
                              );
                            } else if (constraints.maxWidth >= 600) {
                              // Tablet: card rows with structured layout
                              return _CardList(
                                items: items,
                                branches: data.branches,
                                onAdjust: _onAdjust,
                                isTablet: true,
                              );
                            } else {
                              // Mobile: full stacked cards
                              return _CardList(
                                items: items,
                                branches: data.branches,
                                onAdjust: _onAdjust,
                                isTablet: false,
                              );
                            }
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

// ── Search + branch filter row ───────────────────────────────────────────────

class _SearchAndFilter extends StatelessWidget {
  final TextEditingController searchController;
  final List<BranchInfo> branches;
  final String? selectedBranchId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onBranchChanged;

  const _SearchAndFilter({
    required this.searchController,
    required this.branches,
    required this.selectedBranchId,
    required this.onSearchChanged,
    required this.onBranchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final searchField = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search, size: 18),
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
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        );

        final branchItems = <DropdownMenuEntry<String?>>[
          DropdownMenuEntry(
            value: null,
            label: 'All Branches',
            leadingIcon: const Icon(Icons.store_outlined, size: 16),
          ),
          ...branches.map(
            (b) => DropdownMenuEntry(
              value: b.id,
              label: b.name,
            ),
          ),
        ];

        final branchFilter = DropdownMenu<String?>(
          initialSelection: selectedBranchId,
          leadingIcon: const Icon(Icons.store_outlined, size: 16),
          inputDecorationTheme: InputDecorationTheme(
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          dropdownMenuEntries: branchItems,
          onSelected: onBranchChanged,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              branchFilter,
            ],
          );
        }
        return Column(
          children: [
            searchField,
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: branchFilter),
          ],
        );
      },
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

// ── Card list (mobile + tablet) ──────────────────────────────────────────────

class _CardList extends StatelessWidget {
  final List<InventoryItem> items;
  final List<BranchInfo> branches;
  final void Function(InventoryItem, bool) onAdjust;
  final bool isTablet;

  const _CardList({
    required this.items,
    required this.branches,
    required this.onAdjust,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Center(
          child: Column(
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
                isTablet: isTablet,
              ))
          .toList(),
    );
  }
}
