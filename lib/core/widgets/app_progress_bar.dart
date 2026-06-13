import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A thin rounded determinate progress bar with an optional label row.
///
/// Used for receiving progress, inventory levels and any "x of y" completion so
/// progress reads identically everywhere. [value] is clamped to 0..1.
class AppProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;

  /// Optional label shown above the bar (left side).
  final String? label;

  /// Optional trailing text shown opposite [label] (e.g. "24/30").
  final String? trailing;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
    this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 1.0);
    final barColor = color ?? AppColors.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || trailing != null) ...[
          Row(
            children: [
              if (label != null)
                Expanded(
                  child: Text(
                    label!,
                    style: getOutfitStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: getOutfitStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: height,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}
