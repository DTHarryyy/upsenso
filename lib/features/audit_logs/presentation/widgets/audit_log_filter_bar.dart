import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_date_range_picker.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
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

        // Collect distinct entity types from currently loaded logs.
        final entityTypes = loaded == null
            ? <String>[]
            : (loaded.logs
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
              : Row(
                  children: [
                    // ── Search ──────────────────────────────────────────────
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

                    // ── Date range ──────────────────────────────────────────
                    Flexible(
                      flex: 2,
                      child: AppDateRangePicker(
                        value: dateRange,
                        placeholder: 'Date Range',
                        onChanged: (range) {
                          if (range == null) {
                            context.read<AuditLogBloc>().add(
                              const FilterAuditLogsByDateRange(
                                from: null,
                                to: null,
                              ),
                            );
                          } else {
                            context.read<AuditLogBloc>().add(
                              FilterAuditLogsByDateRange(
                                from: range.start,
                                to: range.end,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ── Action type dropdown ────────────────────────────────
                    Flexible(
                      flex: 2,
                      child: AppDropdown<String>(
                        value: loaded?.actionTypeFilter,
                        hint: 'All Actions',
                        dense: true,
                        items: [
                          const AppDropdownItem(
                            value: '',
                            label: 'All Actions',
                          ),
                          ...AuditLogActionType.values.map(
                            (t) => AppDropdownItem(
                              value: t.value,
                              label: t.displayLabel,
                            ),
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

                    // ── Entity type dropdown ────────────────────────────────
                    Flexible(
                      flex: 2,
                      child: AppDropdown<String>(
                        value: loaded?.entityTypeFilter,
                        hint: 'All Entities',
                        dense: true,
                        items: [
                          const AppDropdownItem(
                            value: '',
                            label: 'All Entities',
                          ),
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

                    // ── Clear filters button ────────────────────────────────
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

                    // ── View toggle ───────────────────────────────────────
                    AppViewToggle(
                      current: viewMode,
                      onChanged: onViewModeChanged,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ── Mobile filter layout ────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: Search + view toggle
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
            AppViewToggle(current: viewMode, onChanged: onViewModeChanged),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: Date range | Actions
        Row(
          children: [
            Flexible(
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
            const SizedBox(width: 8),
            Flexible(
              child: AppDropdown<String>(
                value: loaded?.actionTypeFilter,
                hint: 'All Actions',
                dense: true,
                items: [
                  const AppDropdownItem(value: '', label: 'All Actions'),
                  ...AuditLogActionType.values.map(
                    (t) =>
                        AppDropdownItem(value: t.value, label: t.displayLabel),
                  ),
                ],
                onChanged: (v) => context.read<AuditLogBloc>().add(
                  FilterAuditLogsByActionType(
                    actionType: (v == null || v.isEmpty) ? null : v,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 3: Entities (full width) + clear button
        Row(
          children: [
            Flexible(
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
            if (hasFilters) ...[const SizedBox(width: 8), _ClearButton()],
          ],
        ),
      ],
    );
  }
}

// ── Clear button ────────────────────────────────────────────────────────────

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
