import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/features/reports/data/reports_data.dart';

/// Period selector + export action. Stands alone above the nav on phone, or
/// sits inline next to the segmented tabs on tablet+ — the page decides which.
class ReportsControls extends StatelessWidget {
  final ReportPeriod period;
  final String customRangeLabel;
  final ValueChanged<ReportPeriod?> onPeriodChanged;
  final Widget exportButton;

  const ReportsControls({
    super.key,
    required this.period,
    required this.customRangeLabel,
    required this.onPeriodChanged,
    required this.exportButton,
  });

  @override
  Widget build(BuildContext context) {
    final dropdown = AppDropdown<ReportPeriod>(
      value: period,
      dense: true,
      items: [
        ...ReportPeriod.values
            .where((p) => p != ReportPeriod.custom)
            .map((p) => AppDropdownItem(value: p, label: p.label)),
        AppDropdownItem(
          value: ReportPeriod.custom,
          label: customRangeLabel,
          icon: IconlyLight.calendar,
        ),
      ],
      onChanged: onPeriodChanged,
    );

    if (Breakpoints.isPhone(context)) {
      return Row(
        children: [
          Expanded(child: dropdown),
          const SizedBox(width: 8),
          exportButton,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 190, child: dropdown),
        const SizedBox(width: 8),
        exportButton,
      ],
    );
  }
}
