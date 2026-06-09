import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

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
        final pos = -0.3 + 1.6 * _ctrl.value;

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
                  (pos - 0.4).clamp(0.0, 1.0),
                  (pos - 0.2).clamp(0.0, 1.0),
                  pos.clamp(0.0, 1.0),
                  (pos + 0.2).clamp(0.0, 1.0),
                  (pos + 0.4).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08101828),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accent bar
                  Container(
                    width: 4,
                    color: const Color(0xFFE2E8F0),
                  ),

                  // Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // Avatar + dot
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              box(width: 44, height: 44, radius: 22),
                              Positioned(
                                right: -1,
                                bottom: -1,
                                child: box(width: 12, height: 12, radius: 6),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Text lines
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                box(width: 120, height: 14),
                                const SizedBox(height: 7),
                                box(width: 80, height: 11),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    box(width: 58, height: 20, radius: 6),
                                    const SizedBox(width: 6),
                                    box(width: 52, height: 20, radius: 6),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          box(width: 20, height: 20, radius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
