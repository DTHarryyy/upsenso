import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos/core/const/app_colors.dart';

class AuthOptions extends StatelessWidget {
  const AuthOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: implement facebook login
            },
            label: Text(
              'Continue with Facebook',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            icon: const Icon(FontAwesomeIcons.facebook, size: 16),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: implement google login
            },
            label: Text(
              'Continue with Google',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            icon: Image.asset(
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
