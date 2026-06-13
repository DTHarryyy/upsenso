import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A compact −/value/+ numeric stepper.
///
/// Reduces keyboard entry errors on quantity fields (PO lines, receiving, cart)
/// by letting users nudge values directly. Decimals are supported via [step].
class AppCountStepper extends StatelessWidget {
  final double value;
  final double min;
  final double? max;
  final double step;
  final ValueChanged<double> onChanged;

  const AppCountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrement = value - step >= min;
    final canIncrement = max == null || value + step <= max!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(
            icon: Icons.remove_rounded,
            enabled: canDecrement,
            onTap: () => onChanged(value - step),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: Text(
              _format(value),
              textAlign: TextAlign.center,
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _btn(
            icon: Icons.add_rounded,
            enabled: canIncrement,
            onTap: () => onChanged(value + step),
          ),
        ],
      ),
    );
  }

  // Drop the trailing ".0" for whole numbers so pieces read cleanly.
  String _format(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Widget _btn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.brand : AppColors.disabled,
        ),
      ),
    );
  }
}
