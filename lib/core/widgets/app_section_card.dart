import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

/// A premium SaaS-grade card container for grouping form sections.
///
/// Renders an elevated rounded surface with an icon badge + title header,
/// followed by [children]. The soft shadow gives depth without being heavy.
class AppSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  /// Override the icon accent colour. Defaults to [AppColors.brand].
  final Color? iconColor;

  /// Optional widget shown at the trailing end of the header row (e.g. a badge
  /// or a collapse arrow).
  final Widget? trailing;

  const AppSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.brand;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x04101828),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon badge
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: effectiveIconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
