import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

class AuthOptions extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final bool isLoading;

  const AuthOptions({super.key, this.onGooglePressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Container(height: 1, color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Or sign in with',
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            ),
            Expanded(child: Container(height: 1, color: AppColors.divider)),
          ],
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onGooglePressed,
            label: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            icon: isLoading
                ? const SizedBox.shrink()
                : Image.asset(
                    'assets/images/Google-icon.png',
                    width: 18,
                    height: 18,
                  ),
          ),
        ),
      ],
    );
  }
}
