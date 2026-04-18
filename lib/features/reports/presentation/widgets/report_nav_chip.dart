import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

/// A reusable tab navigation chip used in Reports & Analytics (and any other
/// tabbed view that needs a pill-style navigator row).
class ReportNavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ReportNavChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.brand : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal scrollable row of [ReportNavChip] tabs.
///
/// Example:
/// ```dart
/// ReportNavChipBar(
///   tabs: const [
///     ReportTab(icon: Icons.bar_chart, label: 'Sales Report'),
///     ReportTab(icon: Icons.inventory_2_outlined, label: 'Inventory Health'),
///   ],
///   selectedIndex: _tab,
///   onTabSelected: (i) => setState(() => _tab = i),
/// )
/// ```
class ReportNavChipBar extends StatelessWidget {
  final List<ReportTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const ReportNavChipBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(tabs.length, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < tabs.length - 1 ? 2 : 0),
              child: ReportNavChip(
                icon: tabs[i].icon,
                label: tabs[i].label,
                isSelected: selectedIndex == i,
                onTap: () => onTabSelected(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class ReportTab {
  final IconData icon;
  final String label;
  const ReportTab({required this.icon, required this.label});
}
