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

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
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
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.home);
        } else if (state is AuthError) {
          setState(() => _errorMessage = state.message);
        }
      },
      builder: (context, state) {
        if (state is AuthOAuthInProgress) {
          return OAuthInProgressView(
            provider: state.provider,
            actionLabel: 'sign-in',
          );
        }

        final isEmailLoading =
            state is AuthLoading && state.type == AuthLoadingType.email;
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
                  AppStrings.signInHeadline,
                  style: AppTextStyles.headline(
                    context,
                  ).copyWith(color: AppColors.textPrimary, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.signInSubHeadline,
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
                const SizedBox(height: 8),

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
                  textInputAction: TextInputAction.done,
                  onChanged: (v) {
                    setState(() {});
                    _clearError(v);
                  },
                  onFieldSubmitted: (_) => _onSubmit(),
                  validator: (v) =>
                      Validators.required(v, fieldName: 'Password'),
                ),
                const SizedBox(height: 8),

                // Forgot / Sign up row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.forgotPassword),
                      child: Text(
                        AppStrings.forgotPassword,
                        style: const TextStyle(
                          color: AppColors.brand,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.signUp),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sign in button
                FilledButton(
                  onPressed: isEmailLoading ? null : _onSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isEmailLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(AppStrings.signIn),
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
