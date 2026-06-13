import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// Restock / Adjust action pair under the stock hero. Restock is the primary
/// (solid brand) action; Adjust is a quieter neutral secondary.
class IngredientQuickActions extends StatelessWidget {
  final VoidCallback onRestock;
  final VoidCallback onAdjust;

  const IngredientQuickActions({
    super.key,
    required this.onRestock,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Restock',
            icon: Icons.add_rounded,
            primary: true,
            onTap: onRestock,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Adjust Stock',
            icon: Icons.tune_rounded,
            primary: false,
            onTap: onAdjust,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.textInverse : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: primary ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: primary ? null : Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
