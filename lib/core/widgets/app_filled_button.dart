import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A full-width [FilledButton] in the app brand colour.
///
/// Shows a [CircularProgressIndicator] in place of [label] when [loading] is
/// true. Disabled automatically when [loading] is true or [onPressed] is null.
/// Renders a leading [icon] when provided.
class AppFilledButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double radius;
  final double verticalPadding;

  /// Optional leading icon (hidden while [loading]).
  final IconData? icon;

  const AppFilledButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.radius = 12,
    this.verticalPadding = 16,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !loading && onPressed != null;
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        disabledBackgroundColor: AppColors.disabled,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        minimumSize: const Size(double.infinity, 0),
        elevation: isEnabled ? 0 : 0,
        shadowColor: AppColors.brand.withAlpha(60),
      ).copyWith(
        // Subtle lift shadow on enabled state only
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return 0;
          if (states.contains(WidgetState.pressed)) return 0;
          return 0;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withAlpha(20);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withAlpha(12);
          }
          return null;
        }),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: Colors.white),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: getOutfitStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
    );
  }
}
