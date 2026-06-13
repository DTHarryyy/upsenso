import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

/// A single shimmering placeholder block.
///
/// Self-contained animated gradient — no third-party shimmer package — so list
/// and detail screens can show structure-preserving loading states instead of a
/// bare spinner on an offline-first app that should feel instant.
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const AppSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Slide a light highlight band across the muted base color.
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * t, 0),
              end: Alignment(1 - 2 * t, 0),
              colors: const [
                AppColors.surfaceAlt,
                AppColors.borderSoft,
                AppColors.surfaceAlt,
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// Repeats a [itemBuilder] placeholder card [itemCount] times.
///
/// Defaults to a generic stacked-line card so most lists can drop it in
/// without supplying a custom builder.
class AppSkeletonList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final IndexedWidgetBuilder? itemBuilder;

  const AppSkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 40),
    this.spacing = 8,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => SizedBox(height: spacing),
      itemBuilder: itemBuilder ?? (_, _) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              AppSkeleton(width: 120, height: 14),
              Spacer(),
              AppSkeleton(width: 56, height: 18, radius: 6),
            ],
          ),
          SizedBox(height: 10),
          AppSkeleton(width: 160, height: 12),
          SizedBox(height: 12),
          Row(
            children: [
              AppSkeleton(width: 80, height: 12),
              Spacer(),
              AppSkeleton(width: 64, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}
