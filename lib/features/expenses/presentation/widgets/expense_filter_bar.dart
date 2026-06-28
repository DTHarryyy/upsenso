import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_date_range_picker.dart';
import 'package:pos/core/widgets/app_filter_chip.dart';
import 'package:pos/core/widgets/app_filter_toolbar.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/core/widgets/app_section_label.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';

class ExpenseFilterBar extends StatelessWidget {
  final AppViewMode viewMode;
  final ValueChanged<AppViewMode> onViewModeChanged;
  final ValueChanged<String> onSearchChanged;
  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final String? categoryFilter;
  final List<String> categories;
  final ValueChanged<String?> onCategoryChanged;

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
  });

  bool get _hasActiveFilters => dateRange != null || categoryFilter != null;

  void _openFilterSheet(BuildContext context) {
    showAppModal<void>(
      context: context,
      builder: (_) => _ExpenseFilterSheet(
        dateRange: dateRange,
        onDateRangeChanged: onDateRangeChanged,
        categoryFilter: categoryFilter,
        categories: categories,
        onCategoryChanged: onCategoryChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFilterToolbar(
      searchHint: 'Search by vendor or category...',
      onSearchChanged: onSearchChanged,
      hasActiveFilters: _hasActiveFilters,
      onFilterTap: () => _openFilterSheet(context),
      viewMode: viewMode,
      onViewModeChanged: onViewModeChanged,
    );
  }
}

// ── Filter bottom sheet ─────────────────────────────────────────────────────

class _ExpenseFilterSheet extends StatefulWidget {
  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final String? categoryFilter;
  final List<String> categories;
  final ValueChanged<String?> onCategoryChanged;

  const _ExpenseFilterSheet({
    required this.dateRange,
    required this.onDateRangeChanged,
    required this.categoryFilter,
    required this.categories,
    required this.onCategoryChanged,
  });

  @override
  State<_ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<_ExpenseFilterSheet> {
  late DateTimeRange? _dateRange;
  late String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.dateRange;
    _categoryFilter = widget.categoryFilter;
  }

  void _setDateRange(DateTimeRange? range) {
    setState(() => _dateRange = range);
    widget.onDateRangeChanged(range);
  }

  void _setCategory(String? category) {
    setState(() => _categoryFilter = category);
    widget.onCategoryChanged(category);
  }

  void _clearAll() {
    setState(() {
      _dateRange = null;
      _categoryFilter = null;
    });
    widget.onDateRangeChanged(null);
    widget.onCategoryChanged(null);
  }

  bool get _hasFilters => _dateRange != null || _categoryFilter != null;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title: 'Filters',
      titleTrailing: _hasFilters
          ? GestureDetector(
              onTap: _clearAll,
              child: Text(
                'Clear all',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            )
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date range ────────────────────────────────────────────────
            AppSectionLabel(label: 'DATE RANGE'),
            const SizedBox(height: 10),
            AppDateRangePicker(
              value: _dateRange,
              placeholder: 'Select date range',
              onChanged: _setDateRange,
            ),
            const SizedBox(height: 20),

            // ── Category ──────────────────────────────────────────────────
            AppSectionLabel(label: 'CATEGORY'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppFilterChip(
                  label: 'All',
                  isSelected: _categoryFilter == null,
                  onTap: () => _setCategory(null),
                ),
                for (final category in widget.categories)
                  AppFilterChip(
                    label: category,
                    isSelected: _categoryFilter == category,
                    onTap: () => _setCategory(
                      _categoryFilter == category ? null : category,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
