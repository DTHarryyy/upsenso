import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

class EmployeeStatusBadge extends StatelessWidget {
  final bool isActive;

  /// Suspended because the plan ran out of seats, not because anyone chose to
  /// deactivate them. Worth its own pill: "Inactive" reads as a decision the
  /// owner made, and sends them hunting for a toggle that won't help.
  final bool needsSeat;

  const EmployeeStatusBadge({
    super.key,
    required this.isActive,
    this.needsSeat = false,
  });

  @override
  Widget build(BuildContext context) {
    if (needsSeat) return const _NeedsSeatPill();
    if (isActive) {
      return _ActivePill();
    }
    return const _InactivePill();
  }
}

class _NeedsSeatPill extends StatelessWidget {
  const _NeedsSeatPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 11,
            color: AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            'Needs a seat',
            style: getOutfitStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Active',
        style: getOutfitStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _InactivePill extends StatelessWidget {
  const _InactivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Inactive',
            style: getOutfitStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
