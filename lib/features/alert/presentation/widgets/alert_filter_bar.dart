import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/widgets/app_dropdown.dart';

class AlertFilterBar extends StatelessWidget {
  final String selectedStatus;
  final String selectedSeverity;
  final int newCount;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSeverityChanged;

  const AlertFilterBar({
    super.key,
    required this.selectedStatus,
    required this.selectedSeverity,
    required this.newCount,
    required this.onStatusChanged,
    required this.onSeverityChanged,
  });

  static const _statuses = ['All', 'New', 'Investigating', 'Resolved'];

  static final _severityItems = [
    AppDropdownItem(value: 'All Severity', label: 'All Severity'),
    AppDropdownItem(value: 'High', label: 'High'),
    AppDropdownItem(value: 'Medium', label: 'Medium'),
    AppDropdownItem(value: 'Low', label: 'Low'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statuses.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final status = _statuses[i];
                  final isSelected = selectedStatus == status;
                  final showBadge = status == 'New' && newCount > 0;

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status,
                          style: AppTextStyles.caption(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.surface
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (showBadge) ...[
                          const SizedBox(width: 5),
                          Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.surface.withValues(alpha: 0.3)
                                  : AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$newCount',
                              style: AppTextStyles.caption(context).copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => onStatusChanged(status),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.brand,
                    showCheckmark: false,
                    side: BorderSide(
                      color:
                          isSelected ? AppColors.brand : AppColors.borderSoft,
                      width: isSelected ? 1.5 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: AppDropdown<String>(
              value: selectedSeverity,
              dense: true,
              items: _severityItems,
              onChanged: (v) {
                if (v != null) onSeverityChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
