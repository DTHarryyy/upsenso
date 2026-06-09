import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_filter_chip.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/features/business/domain/entities/branch.dart';
import 'package:pos/features/employees/presentation/bloc/employee_bloc.dart';
import 'package:pos/features/employees/presentation/bloc/employee_event.dart';
import 'package:pos/features/employees/presentation/bloc/employee_state.dart';

const _kRoles = [
  (role: 'Branch Manager', color: Color(0xFF7C3AED)),
  (role: 'Cashier', color: Color(0xFF1D4ED8)),
  (role: 'Inventory Staff', color: Color(0xFF0F766E)),
  (role: 'Business Owner', color: Color(0xFFB45309)),
];

class EmployeeFilterBar extends StatefulWidget {
  final List<Branch> branches;

  const EmployeeFilterBar({super.key, required this.branches});

  @override
  State<EmployeeFilterBar> createState() => _EmployeeFilterBarState();
}

class _EmployeeFilterBarState extends State<EmployeeFilterBar> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  EmployeeLoaded? _resolveLoaded(EmployeeState state) {
    if (state is EmployeeLoaded) return state;
    if (state is EmployeeOperationInProgress) return state.previous;
    if (state is EmployeeOperationSuccess) return state.loaded;
    if (state is EmployeeValidationFailure) return state.loaded;
    return null;
  }

  void _showFilterSheet(EmployeeLoaded? loaded) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        bloc: context.read<EmployeeBloc>(),
        loaded: loaded,
        branches: widget.branches,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search + filter icon 
          Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  controller: _searchController,
                  hint: 'Search employees…',
                  onChanged: (q) =>
                      context.read<EmployeeBloc>().add(SearchEmployees(q)),
                ),
              ),
              const SizedBox(width: 10),
              BlocBuilder<EmployeeBloc, EmployeeState>(
                buildWhen: (p, c) {
                  final pf = _resolveLoaded(p);
                  final cf = _resolveLoaded(c);
                  return (pf?.isActiveFilter != cf?.isActiveFilter) ||
                      (pf?.branchFilter != cf?.branchFilter);
                },
                builder: (context, state) {
                  final loaded = _resolveLoaded(state);
                  return _FilterButton(
                    hasActiveFilters: loaded?.isActiveFilter != null ||
                        loaded?.branchFilter != null,
                    onTap: () => _showFilterSheet(loaded),
                  );
                },
              ),
            ],
          ),

          // Role quick-filter chips
          const SizedBox(height: 10),
          BlocBuilder<EmployeeBloc, EmployeeState>(
            buildWhen: (p, c) =>
                _resolveLoaded(p)?.roleFilter !=
                _resolveLoaded(c)?.roleFilter,
            builder: (context, state) {
              final loaded = _resolveLoaded(state);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppFilterChip(
                      label: 'All',
                      isSelected: loaded?.roleFilter == null,
                      onTap: () => context
                          .read<EmployeeBloc>()
                          .add(const SetRoleFilter(null)),
                    ),
                    for (final entry in _kRoles) ...[
                      const SizedBox(width: 8),
                      AppFilterChip(
                        label: entry.role,
                        isSelected: loaded?.roleFilter == entry.role,
                        selectedColor: entry.color,
                        onTap: () => context.read<EmployeeBloc>().add(
                              SetRoleFilter(
                                loaded?.roleFilter == entry.role
                                    ? null
                                    : entry.role,
                              ),
                            ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Filter icon button

class _FilterButton extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onTap;

  const _FilterButton({required this.hasActiveFilters, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasActiveFilters ? AppColors.brand : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasActiveFilters ? AppColors.brand : AppColors.borderSoft,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              IconlyLight.filter,
              size: 20,
              color: hasActiveFilters ? Colors.white : AppColors.textSecondary,
            ),
            if (hasActiveFilters)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBBF24),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter bottom sheet ─────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final EmployeeBloc bloc;
  final EmployeeLoaded? loaded;
  final List<Branch> branches;

  const _FilterSheet({
    required this.bloc,
    required this.branches,
    this.loaded,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool? _isActiveFilter;
  late String? _branchFilter;

  @override
  void initState() {
    super.initState();
    _isActiveFilter = widget.loaded?.isActiveFilter;
    _branchFilter = widget.loaded?.branchFilter;
  }

  void _setStatus(bool? value) {
    setState(() => _isActiveFilter = value);
    widget.bloc.add(SetStatusFilter(value));
  }

  void _setBranch(String? branchId) {
    setState(() => _branchFilter = branchId);
    widget.bloc.add(SetBranchFilter(branchId));
  }

  void _clearAll() {
    setState(() {
      _isActiveFilter = null;
      _branchFilter = null;
    });
    widget.bloc.add(const SetStatusFilter(null));
    widget.bloc.add(const SetBranchFilter(null));
  }

  bool get _hasFilters => _isActiveFilter != null || _branchFilter != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Text(
                'Filters',
                style: getOutfitStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_hasFilters)
                GestureDetector(
                  onTap: _clearAll,
                  child: Text(
                    'Clear all',
                    style: getOutfitStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brand,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Status ────────────────────────────────────────────────────
          _SectionLabel(label: 'STATUS'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppFilterChip(
                label: 'All',
                isSelected: _isActiveFilter == null,
                onTap: () => _setStatus(null),
              ),
              AppFilterChip(
                label: 'Active',
                isSelected: _isActiveFilter == true,
                selectedColor: AppColors.success,
                onTap: () => _setStatus(_isActiveFilter == true ? null : true),
              ),
              AppFilterChip(
                label: 'Inactive',
                isSelected: _isActiveFilter == false,
                selectedColor: AppColors.textMuted,
                onTap: () =>
                    _setStatus(_isActiveFilter == false ? null : false),
              ),
            ],
          ),

          if (widget.branches.isNotEmpty) ...[
            const SizedBox(height: 20),

            // ── Branch ────────────────────────────────────────────────
            _SectionLabel(label: 'BRANCH'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppFilterChip(
                  label: 'All',
                  isSelected: _branchFilter == null,
                  onTap: () => _setBranch(null),
                ),
                for (final branch in widget.branches)
                  AppFilterChip(
                    label: branch.name,
                    isSelected: _branchFilter == branch.id,
                    onTap: () => _setBranch(
                      _branchFilter == branch.id ? null : branch.id,
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: getOutfitStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}
