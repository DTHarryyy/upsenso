import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

/// Shimmer skeleton that mirrors the exact layout of [EmployeeCard].
class EmployeeCardSkeleton extends StatefulWidget {
  const EmployeeCardSkeleton({super.key});

  @override
  State<EmployeeCardSkeleton> createState() => _EmployeeCardSkeletonState();
}

class _EmployeeCardSkeletonState extends State<EmployeeCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final shimmerPos = -0.3 + 1.6 * _ctrl.value;

        Widget box({double? width, double height = 12, double radius = 6}) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                colors: const [
                  Color(0xFFE2E8F0),
                  Color(0xFFECF0F6),
                  Color(0xFFF5F8FC),
                  Color(0xFFECF0F6),
                  Color(0xFFE2E8F0),
                ],
                stops: [
                  (shimmerPos - 0.4).clamp(0.0, 1.0),
                  (shimmerPos - 0.2).clamp(0.0, 1.0),
                  shimmerPos.clamp(0.0, 1.0),
                  (shimmerPos + 0.2).clamp(0.0, 1.0),
                  (shimmerPos + 0.4).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06101828),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header row ──────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar circle
                  box(width: 44, height: 44, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        box(width: 110, height: 14),
                        const SizedBox(height: 6),
                        // Email
                        box(height: 11),
                        const SizedBox(height: 10),
                        // Badges
                        Row(
                          children: [
                            box(width: 88, height: 22, radius: 20),
                            const SizedBox(width: 6),
                            box(width: 52, height: 22, radius: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu icon placeholder
                  box(width: 20, height: 20, radius: 4),
                ],
              ),

              const SizedBox(height: 14),
              Container(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 10),

              // ── Footer row ──────────────────────────────────────────
              Row(
                children: [
                  box(width: 13, height: 13, radius: 3),
                  const SizedBox(width: 4),
                  box(width: 60, height: 11),
                  const Spacer(),
                  box(width: 13, height: 13, radius: 3),
                  const SizedBox(width: 4),
                  box(width: 60, height: 11),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
