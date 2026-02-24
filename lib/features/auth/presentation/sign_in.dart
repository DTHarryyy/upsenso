import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/validators.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/features/auth/presentation/widgets/auth_options.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

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
                  Image.asset(
                    'assets/icons/AppIconNoBg.png',
                    width: 64,
                    height: 64,
                  ),
                  Text(
                    AppStrings.signInHeadline,
                    style: AppTextStyles.headline(
                      context,
                    ).copyWith(color: AppColors.textPrimary, height: 2),
                  ),
                  Text(
                    AppStrings.signInSubHeadline,
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          //TODO: Handle forgot password logic
                        },
                        child: Text(
                          AppStrings.forgotPassword,
                          style: TextStyle(color: AppColors.brand),
                        ),
                      ),
                      Row(
                        spacing: 5,
                        children: [
                          Text(
                            AppStrings.alreadyHaveAccount,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.go(AppRoutes.signUp);
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(color: AppColors.brand),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          //TODO: Handle sign-in logic
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
                          'Or sign in with',
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
