import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';

/// A bottom-anchored action bar with an optional summary and up to two buttons.
///
/// Keeps the primary action and a running summary (e.g. item count + total)
/// always reachable without scrolling to the bottom of long forms or details.
/// Place it in the [Scaffold.bottomNavigationBar] slot for safe-area handling.
class AppStickyActionBar extends StatelessWidget {
  /// Optional summary row shown above the buttons (e.g. count + total).
  final Widget? summary;

  /// Primary (right-most) action — required, full width when alone.
  final Widget primary;

  /// Optional secondary action shown to the left of the primary.
  final Widget? secondary;

  const AppStickyActionBar({
    super.key,
    required this.primary,
    this.summary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = Row(
      children: [
        if (secondary != null) ...[
          Expanded(child: secondary!),
          const SizedBox(width: 12),
        ],
        Expanded(child: primary),
      ],
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderSoft)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F101828),
              blurRadius: 16,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            // Keep the actions aligned with the centred page body instead of
            // stretching edge-to-edge on tablet/desktop.
            constraints: BoxConstraints(
              maxWidth: Breakpoints.maxContentWidth(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (summary != null) ...[summary!, const SizedBox(height: 12)],
                buttons,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
