import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

class ReportTab {
  final IconData icon;
  final String label;
  const ReportTab({required this.icon, required this.label});
}

/// Full-width segmented control. Every tab gets an equal segment with icon +
/// label; the active segment lifts onto a white card with brand-tinted text.
/// Built on [CupertinoSlidingSegmentedControl] so the active card glides to
/// the tapped segment with the native spring animation, instead of each
/// segment cross-fading its own background independently.
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
    if (tabs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / tabs.length;
          // Fill exactly what the parent hands us (e.g. the pinned header's
          // fixed extent minus this bar's own border) instead of a hardcoded
          // height — a mismatch there is a hard overflow, not just a clip.
          final segmentHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 40.0;
          return CupertinoSlidingSegmentedControl<int>(
            groupValue: selectedIndex,
            backgroundColor: Colors.transparent,
            thumbColor: AppColors.surface,
            padding: EdgeInsets.zero,
            onValueChanged: (i) {
              if (i != null) onTabSelected(i);
            },
            children: {
              for (var i = 0; i < tabs.length; i++)
                i: SizedBox(
                  width: segmentWidth,
                  height: segmentHeight,
                  child: _SegmentContent(
                    tab: tabs[i],
                    isSelected: selectedIndex == i,
                  ),
                ),
            },
          );
        },
      ),
    );
  }
}

class _SegmentContent extends StatelessWidget {
  final ReportTab tab;
  final bool isSelected;

  const _SegmentContent({required this.tab, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? AppColors.brand : AppColors.textSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(tab.icon, size: 16, color: fg),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            tab.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              color: fg,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
