import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/app_date_filter_dropdown.dart';
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

        final entityTypes = loaded == null
            ? <String>[]
            : (loaded.allLogs
                  .map((l) => l.entityType)
                  .where((t) => t.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort());

        final bloc = context.read<AuditLogBloc>();

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      hint: 'Search by user or record ID...',
                      onChanged: (q) => bloc.add(SearchAuditLogs(query: q)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppViewToggle(
                    current: viewMode,
                    onChanged: onViewModeChanged,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Date / Action Type / Entity Type dropdown filters
              Row(
                children: [
                  Expanded(
                    child: AppDateFilterDropdown(
                      value: dateRange,
                      onChanged: (range) => bloc.add(
                        FilterAuditLogsByDateRange(
                          from: range?.start,
                          to: range?.end,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppDropdown<String>(
                      value: loaded?.actionTypeFilter,
                      hint: 'All Actions',
                      dense: true,
                      searchable: true,
                      searchHint: 'Search action types...',
                      items: [
                        const AppDropdownItem(value: '', label: 'All Actions'),
                        ...AuditLogActionType.values.map(
                          (t) => AppDropdownItem(
                            value: t.value,
                            label: t.displayLabel,
                          ),
                        ),
                      ],
                      onChanged: (v) => bloc.add(
                        FilterAuditLogsByActionType(
                          actionType: (v == null || v.isEmpty) ? null : v,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
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
                      onChanged: (v) => bloc.add(
                        FilterAuditLogsByEntityType(
                          entityType: (v == null || v.isEmpty) ? null : v,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
