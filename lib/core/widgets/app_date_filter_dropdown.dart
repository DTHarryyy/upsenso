import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/utils/business_clock.dart';
import 'package:pos/core/widgets/app_dropdown.dart';

enum _DatePreset { allTime, today, thisWeek, thisMonth, custom }

DateTimeRange _rangeFor(_DatePreset preset) {
  final today = BusinessClock.today();
  return switch (preset) {
    _DatePreset.today => DateTimeRange(start: today, end: today),
    _DatePreset.thisWeek => DateTimeRange(
      start: today.subtract(Duration(days: today.weekday - 1)),
      end: today,
    ),
    _DatePreset.thisMonth => DateTimeRange(
      start: DateTime(today.year, today.month),
      end: today,
    ),
    _DatePreset.allTime || _DatePreset.custom => DateTimeRange(
      start: today,
      end: today,
    ),
  };
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

_DatePreset _presetFor(DateTimeRange? range) {
  if (range == null) return _DatePreset.allTime;
  for (final preset in [
    _DatePreset.today,
    _DatePreset.thisWeek,
    _DatePreset.thisMonth,
  ]) {
    final presetRange = _rangeFor(preset);
    if (_sameDay(range.start, presetRange.start) &&
        _sameDay(range.end, presetRange.end)) {
      return preset;
    }
  }
  return _DatePreset.custom;
}

String _fmtDate(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

/// Preset date-range filter (All Time / Today / This Week / This Month /
/// Custom Range) built on [AppDropdown] — the shared filter-dropdown look, so
/// restyling it once applies everywhere this is used.
class AppDateFilterDropdown extends StatelessWidget {
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;
  final String allTimeLabel;

  const AppDateFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.allTimeLabel = 'All Time',
  });

  Future<void> _pickCustomRange(BuildContext context) async {
    final today = BusinessClock.today();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: value,
    );
    if (picked != null) onChanged(picked);
  }

  void _onPresetChanged(BuildContext context, _DatePreset? preset) {
    if (preset == null) return;
    switch (preset) {
      case _DatePreset.allTime:
        onChanged(null);
      case _DatePreset.custom:
        _pickCustomRange(context);
      case _DatePreset.today:
      case _DatePreset.thisWeek:
      case _DatePreset.thisMonth:
        onChanged(_rangeFor(preset));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _presetFor(value);
    final customLabel = selected == _DatePreset.custom && value != null
        ? '${_fmtDate(value!.start)} - ${_fmtDate(value!.end)}'
        : 'Custom Range';

    return AppDropdown<_DatePreset>(
      value: selected,
      dense: true,
      items: [
        AppDropdownItem(value: _DatePreset.allTime, label: allTimeLabel),
        const AppDropdownItem(value: _DatePreset.today, label: 'Today'),
        const AppDropdownItem(value: _DatePreset.thisWeek, label: 'This Week'),
        const AppDropdownItem(
          value: _DatePreset.thisMonth,
          label: 'This Month',
        ),
        AppDropdownItem(
          value: _DatePreset.custom,
          label: customLabel,
          icon: IconlyLight.calendar,
        ),
      ],
      onChanged: (v) => _onPresetChanged(context, v),
    );
  }
}
