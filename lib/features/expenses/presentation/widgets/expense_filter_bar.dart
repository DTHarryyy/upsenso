import 'package:flutter/material.dart';
import 'package:pos/core/widgets/app_date_filter_dropdown.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';

const _kStatusLabels = {
  ExpenseStatus.pending: 'Pending',
  ExpenseStatus.approved: 'Approved',
  ExpenseStatus.rejected: 'Rejected',
  ExpenseStatus.draft: 'Draft',
};

class ExpenseFilterBar extends StatelessWidget {
  final AppViewMode viewMode;
  final ValueChanged<AppViewMode> onViewModeChanged;
  final ValueChanged<String> onSearchChanged;
  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final String? categoryFilter;
  final List<String> categories;
  final ValueChanged<String?> onCategoryChanged;
  final ExpenseStatus? statusFilter;
  final ValueChanged<ExpenseStatus?> onStatusChanged;
  final int pendingCount;

  const ExpenseFilterBar({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onSearchChanged,
    required this.dateRange,
    required this.onDateRangeChanged,
    required this.categoryFilter,
    required this.categories,
    required this.onCategoryChanged,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    final search = AppSearchBar(
      hint: 'Search by vendor or category...',
      onChanged: onSearchChanged,
    );
    final toggle = AppViewToggle(current: viewMode, onChanged: onViewModeChanged);
    final category = _categoryDropdown();
    final date = AppDateFilterDropdown(
      value: dateRange,
      onChanged: onDateRangeChanged,
    );
    final status = _statusDropdown();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide screens: everything on one row — search capped on the left, the
        // dropdown filters grouped on the right with the view toggle beside
        // them. Narrower widths fall back to the stacked two-row layout so the
        // controls never get crushed.
        if (constraints.maxWidth >= 920) {
          return Row(
            children: [
              SizedBox(width: 320, child: search),
              const Spacer(),
              SizedBox(width: 180, child: category),
              const SizedBox(width: 8),
              SizedBox(width: 180, child: date),
              const SizedBox(width: 8),
              SizedBox(width: 150, child: status),
              const SizedBox(width: 8),
              toggle,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 8),
                toggle,
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: category),
                const SizedBox(width: 8),
                Expanded(child: date),
                const SizedBox(width: 8),
                Expanded(child: status),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _categoryDropdown() {
    return AppDropdown<String>(
      value: categoryFilter,
      hint: 'All Categories',
      dense: true,
      items: [
        const AppDropdownItem(value: '', label: 'All Categories'),
        for (final category in categories)
          AppDropdownItem(value: category, label: category),
      ],
      onChanged: (v) => onCategoryChanged((v == null || v.isEmpty) ? null : v),
    );
  }

  Widget _statusDropdown() {
    return AppDropdown<String>(
      value: statusFilter?.name,
      hint: 'All Status',
      dense: true,
      items: [
        const AppDropdownItem(value: '', label: 'All Status'),
        for (final entry in _kStatusLabels.entries)
          AppDropdownItem(
            value: entry.key.name,
            label: entry.key == ExpenseStatus.pending && pendingCount > 0
                ? '${entry.value} ($pendingCount)'
                : entry.value,
          ),
      ],
      onChanged: (v) => onStatusChanged(
        (v == null || v.isEmpty) ? null : ExpenseStatus.values.byName(v),
      ),
    );
  }
}
