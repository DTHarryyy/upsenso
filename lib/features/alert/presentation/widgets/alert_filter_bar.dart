import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_filter_chip.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/features/alert/data/alert_model.dart';

/// Search + severity on one row, status chips below.
///
/// Status is the axis an operator switches constantly while triaging, so it
/// gets the one-tap chips — and their badges carry the per-status counts that
/// used to need a row of KPI tiles above the list.
class AlertFilterBar extends StatelessWidget {
  final AlertStatus? statusFilter;
  final AlertSeverity? severityFilter;
  final Map<AlertStatus, int> statusCounts;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AlertStatus?> onStatusChanged;
  final ValueChanged<AlertSeverity?> onSeverityChanged;

  const AlertFilterBar({
    super.key,
    required this.statusFilter,
    required this.severityFilter,
    required this.statusCounts,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSeverityChanged,
  });

  // AppDropdown has no null-valued item, so "All" travels as an empty string.
  static const _allSeverities = '';

  static final _severityItems = [
    const AppDropdownItem(value: _allSeverities, label: 'All Severity'),
    for (final severity in AlertSeverity.values)
      AppDropdownItem(value: severity.dbValue, label: severity.label),
  ];

  // False positives are triaged under "Dismissed" — see FraudLoaded.
  static const _statuses = [
    null,
    AlertStatus.newAlert,
    AlertStatus.investigating,
    AlertStatus.resolved,
    AlertStatus.dismissed,
  ];

  int? _countFor(AlertStatus? status) {
    if (status == null) return null;
    if (status == AlertStatus.dismissed) {
      return (statusCounts[AlertStatus.dismissed] ?? 0) +
          (statusCounts[AlertStatus.falsePositive] ?? 0);
    }
    return statusCounts[status];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  controller: searchController,
                  hint: 'Search...',
                  compact: true,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 140,
                child: AppDropdown<String>(
                  value: severityFilter?.dbValue ?? _allSeverities,
                  dense: true,
                  compact: true,
                  items: _severityItems,
                  onChanged: (v) => onSeverityChanged(
                    v == null || v == _allSeverities
                        ? null
                        : AlertSeverityX.fromDb(v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final status = _statuses[i];
                return AppFilterChip(
                  label: status?.label ?? 'All',
                  isSelected: statusFilter == status,
                  badgeCount: _countFor(status),
                  onTap: () => onStatusChanged(status),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
