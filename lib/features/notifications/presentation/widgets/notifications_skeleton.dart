import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

/// Sliver shimmer skeleton shown while notifications are loading.
class NotificationsSkeleton extends StatefulWidget {
  const NotificationsSkeleton({super.key});

  @override
  State<NotificationsSkeleton> createState() => _NotificationsSkeletonState();
}

class _NotificationsSkeletonState extends State<NotificationsSkeleton>
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
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final shimmerPos = -0.3 + 1.6 * _ctrl.value;
          final gradient = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            colors: const [
              Color(0xFFE2E8F0),
              Color(0xFFECF0F6),
              Color(0xFFF5F8FC),
              Color(0xFFECF0F6),
              Color(0xFFE2E8F0),
            ].map((c) => c).toList(),
            transform: _SlidingGradientTransform(shimmerPos),
          );

          return Column(
            children: List.generate(
              6,
              (i) => _SkeletonTile(gradient: gradient),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonTile extends StatelessWidget {
  final LinearGradient gradient;
  const _SkeletonTile({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(38, 38, gradient, radius: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(16, 140, gradient),
                const SizedBox(height: 8),
                _block(12, double.infinity, gradient),
                const SizedBox(height: 4),
                _block(12, 200, gradient),
                const SizedBox(height: 6),
                _block(10, 80, gradient),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _block(28, 60, gradient, radius: 8),
        ],
      ),
    );
  }

  static Widget _block(
    double height,
    double width,
    LinearGradient gradient, {
    double radius = 6,
  }) {
    return Container(
      height: height,
      width: width == double.infinity ? null : width,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}
