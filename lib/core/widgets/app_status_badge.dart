import 'package:flutter/material.dart';
import 'package:pos/core/const/font_utils.dart';

/// A small rounded status pill — soft background + colored label.
///
/// Reusable across inventory, ingredients, orders, etc. so status chips look
/// identical everywhere. Pass an explicit [background] to override the default
/// soft tint derived from [color].
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
