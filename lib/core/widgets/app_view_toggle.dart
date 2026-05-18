import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

/// Shared enum used by any feature that offers a card/table view switch.
enum AppViewMode { cards, table }

/// A two-button toggle that switches between [AppViewMode.cards] and
/// [AppViewMode.table].  Drop this anywhere you need a card ↔ table control.
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.grid_view_rounded,
            tooltip: 'Card view',
            active: current == AppViewMode.cards,
            isFirst: true,
            onTap: () => onChanged(AppViewMode.cards),
          ),
          Container(width: 1, height: 22, color: AppColors.borderSoft),
          _ToggleBtn(
            icon: Icons.table_rows_rounded,
            tooltip: 'Table view',
            active: current == AppViewMode.table,
            isFirst: false,
            onTap: () => onChanged(AppViewMode.table),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final bool isFirst;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(9) : Radius.zero,
          right: isFirst ? Radius.zero : const Radius.circular(9),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: active ? AppColors.brandSoft : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(9) : Radius.zero,
              right: isFirst ? Radius.zero : const Radius.circular(9),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? AppColors.brand : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
