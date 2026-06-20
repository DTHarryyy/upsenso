import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

/// Premium "report block" container — one consistent shell for every chart,
/// table, or grouped metric on the reports surface.
///
/// An icon badge + title (+ optional subtitle) header sits above [child], on
/// the same soft-shadow card used by [AppSectionCard]. Using this everywhere
/// is what keeps the reports page reading as one product instead of a stack of
/// hand-styled cards.
class ReportSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget child;

  /// Icon accent. Defaults to [AppColors.brand].
  final Color? iconColor;

  /// Trailing header slot — legend, view toggle, count, etc.
  final Widget? trailing;

  final EdgeInsetsGeometry padding;

  const ReportSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.iconColor,
    this.trailing,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.brand;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(color: Color(0x07101828), blurRadius: 20, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x04101828), blurRadius: 6, offset: Offset(0, 1)),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportSectionHeading(
            title: title,
            icon: icon,
            subtitle: subtitle,
            iconColor: accent,
            trailing: trailing,
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

/// Standalone section heading (icon badge + title + optional subtitle/trailing)
/// for content that isn't wrapped in a [ReportSection] card — e.g. the KPI
/// overview row that sits directly on the page background.
class ReportSectionHeading extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Color? iconColor;
  final Widget? trailing;

  const ReportSectionHeading({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.brand;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withAlpha(20),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.subtitle(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}
