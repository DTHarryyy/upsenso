import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

/// Shared enum used by any feature that offers a card/table view switch.
enum AppViewMode { cards, table }

/// A single 44×44 icon button that flips between [AppViewMode.cards] and
/// [AppViewMode.table]. It shows the icon of the view you'll switch *to*, and
/// is sized to sit flush beside [AppFilterButton] in a filter toolbar.
class AppViewToggle extends StatelessWidget {
  final AppViewMode current;
  final ValueChanged<AppViewMode> onChanged;

  const AppViewToggle({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showingCards = current == AppViewMode.cards;
    final target = showingCards ? AppViewMode.table : AppViewMode.cards;
    final icon = showingCards
        ? Icons.table_rows_rounded
        : Icons.grid_view_rounded;

    return Tooltip(
      message: showingCards ? 'Switch to table view' : 'Switch to card view',
      child: GestureDetector(
        onTap: () => onChanged(target),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
