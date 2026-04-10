import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => TypingIndicatorState();
}

class TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot peaks at a different phase
            final phase = i * 0.28;
            final t = (_controller.value + phase) % 1.0;
            // Smooth sine-like curve: 0 → 1 → 0
            final scale = 0.6 + 0.4 * _sineWave(t);
            final opacity = 0.35 + 0.65 * _sineWave(t);

            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 5.0 : 0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.brand
                        .withAlpha((opacity * 255).round()),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Smooth 0→1→0 wave for a given t in [0,1]
  double _sineWave(double t) {
    if (t < 0.5) return t * 2;
    return (1.0 - t) * 2;
  }
}
