import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A small category/tag pill with an optional remove affordance.
///
/// Distinct from [AppFilterChip] (which toggles a filter): this is a passive
/// label used for supplier categories, product tags, etc. Pass [onRemoved] to
/// render a trailing × for editable tag lists.
class AppTagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onRemoved;

  const AppTagChip({
    super.key,
    required this.label,
    this.color,
    this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: EdgeInsets.fromLTRB(10, 4, onRemoved != null ? 6 : 10, 4),
      decoration: BoxDecoration(
        color: c.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
          if (onRemoved != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemoved,
              child: Icon(Icons.close_rounded, size: 14, color: c),
            ),
          ],
        ],
      ),
    );
  }
}
