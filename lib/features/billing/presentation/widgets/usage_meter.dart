import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';

/// One "used / cap" meter row — informative, never a red "LIMIT!" wall (§4.5).
/// A null [max] means unlimited (shown as ∞, no bar).
class UsageMeter extends StatelessWidget {
  final String label;
  final int used;
  final int? max;

  const UsageMeter({
    super.key,
    required this.label,
    required this.used,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final unlimited = max == null;
    final ratio = unlimited || max == 0 ? 0.0 : (used / max!).clamp(0.0, 1.0);
    final atCap = !unlimited && used >= (max ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
            Text(
              unlimited ? '$used  ·  ∞' : '$used / $max',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: atCap ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: unlimited ? 0 : ratio,
            minHeight: 6,
            backgroundColor: AppColors.borderSoft,
            valueColor: AlwaysStoppedAnimation(
                atCap ? AppColors.warning : AppColors.brand),
          ),
        ),
      ],
    );
  }
}
