import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A single item in an [AppPopupMenu].
class AppPopupMenuItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  /// Overrides the default icon colour. Defaults to [AppColors.textSecondary].
  final Color? iconColor;

  const AppPopupMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });
}

/// A stateless action-menu button styled to match the app design system.
///
/// Unlike [AppDropdown], this widget does **not** hold a selected value — each
/// selection fires [onSelected] and the button always shows the [hint] label.
/// The trigger is sized to its content (no [Expanded] inside), so it can be
/// placed as a non-flexible child in a [Row] without causing layout errors.
///
/// ```dart
/// AppPopupMenu<_ExportType>(
///   hint: 'Export',
///   leadingIcon: IconlyLight.upload,
///   dense: true,
///   items: [
///     AppPopupMenuItem(value: _ExportType.pdf,   label: 'Export as PDF',
///                      icon: IconlyLight.document, iconColor: AppColors.error),
///     AppPopupMenuItem(value: _ExportType.excel, label: 'Export as Excel (.xlsx)',
///                      icon: IconlyLight.chart,    iconColor: AppColors.success),
///   ],
///   onSelected: (v) { ... },
/// )
/// ```
class AppPopupMenu<T> extends StatelessWidget {
  /// Label shown on the button when idle.
  final String hint;

  /// Optional leading icon shown to the left of [hint] when not [busy].
  final IconData? leadingIcon;

  final List<AppPopupMenuItem<T>> items;
  final ValueChanged<T>? onSelected;

  /// When true, uses denser vertical padding (matches [AppDropdown] dense mode).
  final bool dense;

  /// When true the button is disabled and a spinner replaces [leadingIcon].
  final bool busy;

  const AppPopupMenu({
    super.key,
    required this.hint,
    required this.items,
    this.leadingIcon,
    this.onSelected,
    this.dense = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final vPad = dense ? 12.0 : 14.0;

    return PopupMenuButton<T>(
      enabled: !busy,
      // Always open below the trigger, never over it.
      position: PopupMenuPosition.under,
      color: AppColors.surface,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      // Outer shape matches the app's card / dropdown radius.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (_) => items
          .map(
            (item) => PopupMenuItem<T>(
              value: item.value,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _ItemRow(item: item),
            ),
          )
          .toList(),
      // ── Trigger button ──────────────────────────────────────────────────────
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: vPad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Leading icon OR spinner when busy
            if (busy) ...[
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
            ] else if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              hint,
              style: getOutfitStyle(
                fontSize: dense ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (!busy) ...[
              const SizedBox(width: 4),
              const Icon(
                IconlyLight.arrow_down_2,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Private item row ─────────────────────────────────────────────────────────

class _ItemRow<T> extends StatelessWidget {
  final AppPopupMenuItem<T> item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: 15,
            color: item.iconColor ?? AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
        ],
        Text(
          item.label,
          style: getOutfitStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
