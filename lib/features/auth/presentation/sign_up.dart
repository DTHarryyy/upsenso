import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/validators.dart';
import 'package:pos/core/routes/app_routes.dart';

import 'package:pos/core/ui/status/status_banner.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';

import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/auth/presentation/widgets/auth_options.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  String? _inlineError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    void clearInlineError() {
      if (_inlineError != null) setState(() => _inlineError = null);
    }

    _emailController.addListener(clearInlineError);
    _passwordController.addListener(clearInlineError);
    _confirmPasswordController.addListener(clearInlineError);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        _emailController.text.trim(),
        _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is! AuthLoading,
      listener: (context, state) {
        if (state is AuthError) {
          setState(() => _inlineError = state.message);

          StatusSnack.show(
            context,
            type: StatusType.error,
            title: 'Sign up failed',
            message: state.message,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/AppIconNoBg.png',
                        width: 64,
                        height: 64,
                      ),
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

                      if (_inlineError != null) ...[
                        const SizedBox(height: 12),
                        StatusBanner(
                          type: StatusType.error,
                          title: 'Sign up failed',
                          message: _inlineError!,
                          onAction: () => context.go(AppRoutes.signIn),
                          actionText: 'Go to Sign In',
                        ),
                      ],

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => Validators.combine(v, [
                          (x) => Validators.required(x, fieldName: "Email"),
                          Validators.email,
                        ]),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: _passwordController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                        ),
                        obscureText: _obscurePassword,
                        onChanged: (value) {
                          setState(() {});
                        },
                        validator: (v) => Validators.combine(v, [
                          (x) => Validators.required(x, fieldName: "Password"),
                          (x) => Validators.strongPassword(x, min: 8),
                        ]),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          suffixIcon: _confirmPasswordController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        onChanged: (value) {
                          setState(() {});
                        },
                        validator: (v) => Validators.combine(v, [
                          (x) => Validators.required(
                            x,
                            fieldName: "Confirm Password",
                          ),
                          (x) => Validators.confirmPassword(
                            x,
                            _passwordController.text,
                          ),
                        ]),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // TODO forgot password
                            },
                            child: Text(
                              AppStrings.forgotPassword,
                              style: TextStyle(color: AppColors.brand),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                AppStrings.alreadyHaveAccount,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => context.go(AppRoutes.signIn),
                                child: Text(
                                  'Sign In',
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
                          onPressed: isLoading ? null : _onSubmit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(AppStrings.signUp),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.divider,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              'Or sign up with',
                              style: AppTextStyles.caption(
                                context,
                              ).copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.divider,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const AuthOptions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
