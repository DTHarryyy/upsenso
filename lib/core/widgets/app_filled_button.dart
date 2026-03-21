import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A full-width [FilledButton] in the app brand color.
///
/// Shows a [CircularProgressIndicator] in place of [label] when [loading] is true.
/// Disabled automatically when [loading] is true or [onPressed] is null.
class AppFilledButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double radius;
  final double verticalPadding;

  const AppFilledButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.radius = 12,
    this.verticalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        disabledBackgroundColor: AppColors.disabled,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: getOutfitStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
    );
  }
}
