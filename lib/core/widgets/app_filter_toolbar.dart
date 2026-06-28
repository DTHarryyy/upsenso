import 'package:flutter/material.dart';
import 'package:pos/core/widgets/app_filter_button.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';

/// Standard filter toolbar: a search field that flexes to fill the row,
/// followed by an optional filter-sheet button and an optional card/table
/// toggle. Keeps the search / filter / view controls the same height and
/// spacing across features — use this instead of re-assembling the row.
///
/// The filter button renders only when both [hasActiveFilters] and
/// [onFilterTap] are provided; the toggle renders only when both [viewMode]
/// and [onViewModeChanged] are provided.
class AppFilterToolbar extends StatelessWidget {
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController? searchController;

  final bool? hasActiveFilters;
  final VoidCallback? onFilterTap;

  final AppViewMode? viewMode;
  final ValueChanged<AppViewMode>? onViewModeChanged;

  const AppFilterToolbar({
    super.key,
    required this.searchHint,
    required this.onSearchChanged,
    this.searchController,
    this.hasActiveFilters,
    this.onFilterTap,
    this.viewMode,
    this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showFilter = hasActiveFilters != null && onFilterTap != null;
    final showToggle = viewMode != null && onViewModeChanged != null;

    return Row(
      children: [
        Expanded(
          child: AppSearchBar(
            hint: searchHint,
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ),
        if (showFilter) ...[
          const SizedBox(width: 8),
          AppFilterButton(
            hasActiveFilters: hasActiveFilters!,
            onTap: onFilterTap!,
          ),
        ],
        if (showToggle) ...[
          const SizedBox(width: 8),
          AppViewToggle(
            current: viewMode!,
            onChanged: onViewModeChanged!,
          ),
        ],
      ],
    );
  }
}
