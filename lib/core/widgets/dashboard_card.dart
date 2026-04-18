import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
class Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const Card({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: child,
    );
  }
}