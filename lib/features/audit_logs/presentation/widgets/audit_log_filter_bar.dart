import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_date_range_picker.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_filter_chip.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_bloc.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_event.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_state.dart';

class AuditLogFilterBar extends StatelessWidget {
  final AppViewMode viewMode;
  final ValueChanged<AppViewMode> onViewModeChanged;

  const AuditLogFilterBar({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditLogBloc, AuditLogState>(
      builder: (context, state) {
        final loaded = state is AuditLogLoaded ? state : null;
        final dateRange = (loaded?.dateFrom != null && loaded?.dateTo != null)
            ? DateTimeRange(start: loaded!.dateFrom!, end: loaded.dateTo!)
            : null;
        final hasFilters = loaded?.hasActiveFilter ?? false;

        final entityTypes = loaded == null
            ? <String>[]
            : (loaded.allLogs
                  .map((l) => l.entityType)
                  .where((t) => t.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort());

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Breakpoints.isPhone(context)
              ? _MobileFilters(
                  loaded: loaded,
                  dateRange: dateRange,
                  entityTypes: entityTypes,
                  hasFilters: hasFilters,
                  viewMode: viewMode,
                  onViewModeChanged: onViewModeChanged,
                )
              : _DesktopFilters(
                  loaded: loaded,
                  dateRange: dateRange,
                  entityTypes: entityTypes,
                  hasFilters: hasFilters,
                  viewMode: viewMode,
                  onViewModeChanged: onViewModeChanged,
                ),
        );
      },
    );
  }
}

// ── Desktop layout (unchanged) ───────────────────────────────────────────────

class _DesktopFilters extends StatelessWidget {
  final AuditLogLoaded? loaded;
  final DateTimeRange? dateRange;
  final List<String> entityTypes;
  final bool hasFilters;
  final AppViewMode viewMode;
  final ValueChanged<AppViewMode> onViewModeChanged;

  const _DesktopFilters({
    required this.loaded,
    required this.dateRange,
    required this.entityTypes,
    required this.hasFilters,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 3,
          child: AppSearchBar(
            hint: 'Search by user or record ID...',
            onChanged: (q) => context.read<AuditLogBloc>().add(
              SearchAuditLogs(query: q),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 2,
          child: AppDateRangePicker(
            value: dateRange,
            placeholder: 'Date Range',
            onChanged: (range) {
              context.read<AuditLogBloc>().add(
                FilterAuditLogsByDateRange(
                  from: range?.start,
                  to: range?.end,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 2,
          child: AppDropdown<String>(
            value: loaded?.actionTypeFilter,
            hint: 'All Actions',
            dense: true,
            items: [
              const AppDropdownItem(value: '', label: 'All Actions'),
              ...AuditLogActionType.values.map(
                (t) => AppDropdownItem(value: t.value, label: t.displayLabel),
              ),
            ],
            onChanged: (v) => context.read<AuditLogBloc>().add(
              FilterAuditLogsByActionType(
                actionType: (v == null || v.isEmpty) ? null : v,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 2,
          child: AppDropdown<String>(
            value: loaded?.entityTypeFilter,
            hint: 'All Entities',
            dense: true,
            items: [
              const AppDropdownItem(value: '', label: 'All Entities'),
              ...entityTypes.map(
                (t) => AppDropdownItem(
                  value: t,
                  label: t.isEmpty
                      ? t
                      : '${t[0].toUpperCase()}${t.substring(1)}',
                ),
              ),
            ],
            onChanged: (v) => context.read<AuditLogBloc>().add(
              FilterAuditLogsByEntityType(
                entityType: (v == null || v.isEmpty) ? null : v,
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: hasFilters
              ? Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: _ClearButton(),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        AppViewToggle(current: viewMode, onChanged: onViewModeChanged),
      ],
    );
  }
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileFilters extends StatelessWidget {
  final AuditLogLoaded? loaded;
  final DateTimeRange? dateRange;
  final List<String> entityTypes;
  final bool hasFilters;
  final AppViewMode viewMode;
  final ValueChanged<AppViewMode> onViewModeChanged;

  const _MobileFilters({
    required this.loaded,
    required this.dateRange,
    required this.entityTypes,
    required this.hasFilters,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AuditLogBloc>(),
        child: _FilterSheet(
          loaded: loaded,
          dateRange: dateRange,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Search + filter btn + view toggle
        Row(
          children: [
            Expanded(
              child: AppSearchBar(
                hint: 'Search…',
                onChanged: (q) =>
                    context.read<AuditLogBloc>().add(SearchAuditLogs(query: q)),
              ),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              hasActiveFilters: hasFilters,
              onTap: () => _openFilterSheet(context),
            ),
            const SizedBox(width: 8),
            AppViewToggle(current: viewMode, onChanged: onViewModeChanged),
          ],
        ),

        // Row 2: Entity type chips (always shown, even if empty — shows "All")
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AppFilterChip(
                label: 'All',
                isSelected: loaded?.entityTypeFilter == null,
                onTap: () => context.read<AuditLogBloc>().add(
                  const FilterAuditLogsByEntityType(entityType: null),
                ),
              ),
              for (final entity in entityTypes) ...[
                const SizedBox(width: 8),
                AppFilterChip(
                  label: entity.isEmpty
                      ? entity
                      : '${entity[0].toUpperCase()}${entity.substring(1)}',
                  isSelected: loaded?.entityTypeFilter == entity,
                  onTap: () => context.read<AuditLogBloc>().add(
                    FilterAuditLogsByEntityType(
                      entityType:
                          loaded?.entityTypeFilter == entity ? null : entity,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Filter icon button ────────────────────────────────────────────────────────

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
              color:
                  hasActiveFilters ? Colors.white : AppColors.textSecondary,
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

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final AuditLogLoaded? loaded;
  final DateTimeRange? dateRange;

  const _FilterSheet({required this.loaded, required this.dateRange});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTimeRange? _dateRange;
  late String? _actionTypeFilter;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.dateRange;
    _actionTypeFilter = widget.loaded?.actionTypeFilter;
  }

  void _setDateRange(DateTimeRange? range) {
    setState(() => _dateRange = range);
    context.read<AuditLogBloc>().add(
      FilterAuditLogsByDateRange(from: range?.start, to: range?.end),
    );
  }

  void _setActionType(String? value) {
    final v = (value == null || value.isEmpty) ? null : value;
    setState(() => _actionTypeFilter = v);
    context.read<AuditLogBloc>().add(
      FilterAuditLogsByActionType(actionType: v),
    );
  }

  void _clearAll() {
    setState(() {
      _dateRange = null;
      _actionTypeFilter = null;
    });
    context.read<AuditLogBloc>().add(const ClearAuditLogFilters());
  }

  bool get _hasFilters => _dateRange != null || _actionTypeFilter != null;

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
          // Handle bar
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

          // ── Date range ────────────────────────────────────────────────
          _SectionLabel(label: 'DATE RANGE'),
          const SizedBox(height: 10),
          AppDateRangePicker(
            value: _dateRange,
            placeholder: 'Select date range',
            onChanged: _setDateRange,
          ),
          const SizedBox(height: 20),

          // ── Action type ───────────────────────────────────────────────
          _SectionLabel(label: 'ACTION TYPE'),
          const SizedBox(height: 10),
          AppDropdown<String>(
            value: _actionTypeFilter,
            hint: 'All Actions',
            items: [
              const AppDropdownItem(value: '', label: 'All Actions'),
              ...AuditLogActionType.values.map(
                (t) => AppDropdownItem(value: t.value, label: t.displayLabel),
              ),
            ],
            onChanged: _setActionType,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

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

// ── Clear button (desktop) ────────────────────────────────────────────────────

class _ClearButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Clear all filters',
      child: InkWell(
        onTap: () =>
            context.read<AuditLogBloc>().add(const ClearAuditLogFilters()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_off_outlined,
                size: 15,
                color: AppColors.error.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 5),
              Text(
                'Clear',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
