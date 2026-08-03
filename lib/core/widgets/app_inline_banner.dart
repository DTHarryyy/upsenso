import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

enum AppInlineBannerVariant { error, warning, info, success }

/// Inline, in-flow status banner for forms — the premium-SaaS alternative to a
/// transient toast. Pass a null [message] to collapse it; the height animates so
/// the surrounding layout never jumps.
class AppInlineBanner extends StatelessWidget {
  final String? message;
  final AppInlineBannerVariant variant;

  const AppInlineBanner({
    super.key,
    required this.message,
    this.variant = AppInlineBannerVariant.error,
  });

  ({Color fg, Color bg, Color border, IconData icon, Color fc}) get _style {
    switch (variant) {
      case AppInlineBannerVariant.error:
        return (
          fg: AppColors.error,
          bg: AppColors.errorSoft,
          border: AppColors.error,
          icon: Icons.error_outline_rounded,
          fc: AppColors.error,
        );
      case AppInlineBannerVariant.warning:
        return (
          fg: AppColors.warning,
          bg: AppColors.warningSoft,
          border: AppColors.warning,
          icon: Icons.warning_amber_rounded,
          fc: AppColors.warning,
        );
      case AppInlineBannerVariant.info:
        return (
          fg: AppColors.info,
          bg: AppColors.infoSoft,
          border: AppColors.info,
          icon: Icons.info_outline_rounded,
          fc: AppColors.info,
        );
      case AppInlineBannerVariant.success:
        return (
          fg: AppColors.success,
          bg: AppColors.successSoft,
          border: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
          fc: AppColors.success,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final hasMessage = message != null && message!.trim().isNotEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: !hasMessage
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: s.bg,
                  borderRadius: BorderRadius.circular(10),
                  // Subtle hairline so the banner reads as a contained surface.
                  border: Border.all(color: s.border.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(s.icon, size: 18, color: s.fg),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message!,
                        style: getOutfitStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: s.fc,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
