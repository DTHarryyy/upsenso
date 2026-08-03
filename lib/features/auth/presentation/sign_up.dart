import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/validators.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/widgets.dart';

import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/auth/presentation/widgets/auth_layout.dart';
import 'package:pos/features/auth/presentation/widgets/auth_options.dart';
import 'package:pos/features/auth/presentation/widgets/oauth_in_progress_view.dart';

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

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        _emailController.text.trim(),
        _passwordController.text,
      ),
    );
  }

  void _onGoogleSignIn() {
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
  }

  // Dismiss the server error once the user starts fixing their input.
  void _clearError(String _) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is! AuthLoading,
      listener: (context, state) {
        if (state is AuthCodeSent) {
          final encodedEmail = Uri.encodeComponent(state.email);
          context.go('${AppRoutes.verification}?email=$encodedEmail');
          return;
        }
        if (state is AuthError) {
          setState(() => _errorMessage = state.message);
        }
      },
      builder: (context, state) {
        if (state is AuthOAuthInProgress) {
          return OAuthInProgressView(
            provider: state.provider,
            actionLabel: 'sign-up',
          );
        }

        final isLoading =
            state is AuthLoading && state.type == AuthLoadingType.signUp;
        final isGoogleLoading =
            state is AuthLoading && state.type == AuthLoadingType.google;
        final isMobile = !Breakpoints.isTablet(context);

        return AuthLayout(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mobile wordmark
                if (isMobile) ...[
                  AuthWordmark(color: AppColors.brand, fontSize: 26),
                  const SizedBox(height: 20),
                ],

                // Heading
                Text(
                  AppStrings.signUpHeadline,
                  style: AppTextStyles.headline(
                    context,
                  ).copyWith(color: AppColors.textPrimary, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.signUpSubHeadline,
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),

                // Inline auth error — replaces the transient toast.
                AppInlineBanner(message: _errorMessage),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: _clearError,
                  validator: (v) => Validators.combine(v, [
                    (x) => Validators.required(x, fieldName: 'Email'),
                    Validators.email,
                  ]),
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: _passwordController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? IconlyLight.hide
                                  : IconlyLight.show,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) {
                    setState(() {});
                    _clearError(v);
                  },
                  validator: (v) => Validators.combine(v, [
                    (x) => Validators.required(x, fieldName: 'Password'),
                    (x) => Validators.strongPassword(x, min: 8),
                  ]),
                ),
                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: _confirmPasswordController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? IconlyLight.hide
                                  : IconlyLight.show,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) {
                    setState(() {});
                    _clearError(v);
                  },
                  onFieldSubmitted: (_) => _onSubmit(),
                  validator: (v) => Validators.combine(v, [
                    (x) =>
                        Validators.required(x, fieldName: 'Confirm Password'),
                    (x) =>
                        Validators.confirmPassword(x, _passwordController.text),
                  ]),
                ),
                const SizedBox(height: 8),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppStrings.alreadyHaveAccount,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.signIn),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sign up button
                FilledButton(
                  onPressed: isLoading ? null : _onSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(AppStrings.signUp),
                ),
                const SizedBox(height: 16),

                // OAuth options
                AuthOptions(
                  isLoading: isGoogleLoading,
                  onGooglePressed: _onGoogleSignIn,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
