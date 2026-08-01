import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';

/// Monthly-vs-annual pill: dark brand track, light active pill, and a "SAVE 17%"
/// chip on the annual side (annual bills 10 months — two are free).
///
/// Shared by the plan ladder and the upgrade sheet, which must never disagree
/// about what a year costs.
class BillingPeriodToggle extends StatelessWidget {
  final bool annual;
  final ValueChanged<bool> onChanged;

  const BillingPeriodToggle({
    super.key,
    required this.annual,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Both labels plus the badge are wider than a narrow phone or the upgrade
    // sheet can give — scale rather than clip, so neither option is lost.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: _track(),
    );
  }

  Widget _track() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Bill annually',
            selected: annual,
            badge: 'SAVE 17%',
            onTap: () => onChanged(true),
          ),
          _Segment(
            label: 'Bill monthly',
            selected: !annual,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.brandDark : Colors.white70,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brandSoft
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.brandDark : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
