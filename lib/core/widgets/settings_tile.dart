import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A grouped settings card: an optional uppercase label above a rounded surface
/// that holds [SettingsTile] rows separated by hairline dividers.
///
/// Used by the Settings page and its System Settings sub-page. Pass a `null`
/// [label] on a page that is already titled (e.g. a focused sub-page).
class SettingsSection extends StatelessWidget {
  final String? label;
  final List<Widget> children;

  const SettingsSection({super.key, this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
            child: Text(
              label!.toUpperCase(),
              style: getOutfitStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(children: _withDividers(children)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Hairline dividers between rows, inset to line up with the row title.
  List<Widget> _withDividers(List<Widget> rows) {
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      out.add(rows[i]);
      if (i != rows.length - 1) {
        out.add(
          const Divider(
            height: 1,
            thickness: 1,
            indent: 54,
            color: AppColors.borderSoft,
          ),
        );
      }
    }
    return out;
  }
}

/// A single settings row: leading line icon, title (+ optional subtitle), and a
/// trailing widget (a custom [trailing], or a chevron when [showChevron]).
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showChevron;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.showChevron = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: getOutfitStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: getOutfitStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showChevron)
                const Icon(
                  IconlyLight.arrow_right_2,
                  size: 18,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
