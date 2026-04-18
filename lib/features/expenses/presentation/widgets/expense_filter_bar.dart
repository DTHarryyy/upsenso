import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/app_date_range_picker.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_search_bar.dart';

class ExpenseFilterBar extends StatelessWidget {
  final bool isTableView;
  final VoidCallback onToggleView;
  final ValueChanged<String> onSearchChanged;
  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final String? categoryFilter;
  final List<String> categories;
  final ValueChanged<String?> onCategoryChanged;

  const ExpenseFilterBar({
    super.key,
    required this.isTableView,
    required this.onToggleView,
    required this.onSearchChanged,
    required this.dateRange,
    required this.onDateRangeChanged,
    required this.categoryFilter,
    required this.categories,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchBar(
                hint: 'Search by vendor or category...',
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 8),
            _ViewToggle(
              isTableView: isTableView,
              onToggle: onToggleView,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppDateRangePicker(
                value: dateRange,
                onChanged: onDateRangeChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppDropdown<String>(
                hint: 'All Categories',
                value: categoryFilter,
                items: [
                  ...categories.map(
                    (c) => AppDropdownItem(value: c, label: c),
                  ),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool isTableView;
  final VoidCallback onToggle;

  const _ViewToggle({required this.isTableView, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(
            icon: Icons.table_rows_rounded,
            selected: isTableView,
            tooltip: 'Table view',
            onTap: () { if (!isTableView) onToggle(); },
            isLeft: true,
          ),
          _Btn(
            icon: Icons.grid_view_rounded,
            selected: !isTableView,
            tooltip: 'Card view',
            onTap: () { if (isTableView) onToggle(); },
            isLeft: false,
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;
  final bool isLeft;

  const _Btn({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: isLeft ? const Radius.circular(9) : Radius.zero,
              bottomLeft: isLeft ? const Radius.circular(9) : Radius.zero,
              topRight: !isLeft ? const Radius.circular(9) : Radius.zero,
              bottomRight: !isLeft ? const Radius.circular(9) : Radius.zero,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? AppColors.textInverse : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
