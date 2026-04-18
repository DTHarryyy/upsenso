import 'package:flutter/material.dart';
import 'package:pos/core/widgets/app_filter_chip.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';

class ExpenseStatusTabs extends StatelessWidget {
  final ExpenseStatus? selected;
  final int pendingCount;
  final ValueChanged<ExpenseStatus?> onSelected;

  const ExpenseStatusTabs({
    super.key,
    required this.selected,
    required this.pendingCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = <(ExpenseStatus?, String, int?)>[
      (null, 'All', null),
      (ExpenseStatus.pending, 'Pending', pendingCount),
      (ExpenseStatus.approved, 'Approved', null),
      (ExpenseStatus.rejected, 'Rejected', null),
      (ExpenseStatus.draft, 'Draft', null),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final (status, label, badge) = tab;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: AppFilterChip(
              label: label,
              isSelected: selected == status,
              onTap: () => onSelected(status),
              badgeCount: badge,
            ),
          );
        }).toList(),
      ),
    );
  }
}
