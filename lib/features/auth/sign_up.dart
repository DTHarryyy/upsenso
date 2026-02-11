import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/validators.dart';
import 'package:pos/features/auth/widgets/auth_options.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.signUpHeadline,
                    style: AppTextStyles.headline(
                      context,
                    ).copyWith(color: AppColors.textPrimary, height: 2),
                  ),
                  Text(
                    AppStrings.signUpSubHeadline,
                    style: AppTextStyles.subtitle(context).copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => Validators.combine(v, [
                      (x) => Validators.required(x, fieldName: "Email"),
                      Validators.email,
                    ]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => Validators.combine(v, [
                      (x) => Validators.required(x, fieldName: "Password"),
                      (x) => Validators.strongPassword(x, min: 8),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                    ),
                    obscureText: true,
                    validator: (v) => Validators.combine(v, [
                      (x) =>
                          Validators.required(x, fieldName: "Confirm Password"),
                      (x) => Validators.confirmPassword(
                        x,
                        passwordController.text,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    spacing: 5,
                    children: [
                      Text(AppStrings.forgotPassword),
                      GestureDetector(
                        onTap: () {
                          //TODO: Handle forgot password logic
                        },
                        child: Text(
                          AppStrings.forgot,
                          style: TextStyle(color: AppColors.brand),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          //TODO: Handle sign-up logic
                        }
                      },
                      child: Text(AppStrings.signUp),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(height: 1, color: AppColors.divider),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Or sign up with',
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1, color: AppColors.divider),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  AuthOptions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
