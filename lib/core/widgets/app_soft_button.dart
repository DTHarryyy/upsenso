import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A low-emphasis pill button: soft grey fill, dark label, no brand colour.
///
/// For actions that belong on a card but shouldn't compete with it — managing a
/// subscription, opening a plan ladder. It hugs its label rather than filling
/// the width, so it reads as a link with a hit area instead of a primary CTA.
class AppSoftButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool showChevron;
  final VoidCallback onPressed;

  const AppSoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.surfaceAlt,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.textPrimary),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: getOutfitStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
