import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/validators.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/auth/presentation/widgets/auth_layout.dart';
import 'package:pos/features/auth/presentation/widgets/auth_options.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is! AuthLoading,
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.home);
        } else if (state is AuthError) {
          StatusSnack.show(
            context,
            type: StatusType.error,
            title: 'Sign in failed',
            message: state.message,
          );
        }
      },
      builder: (context, state) {
        if (state is AuthOAuthInProgress) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      'Completing ${state.provider == 'google' ? 'Google' : 'Facebook'} sign-in...',
                      style: AppTextStyles.body(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we finish setting up your account',
                      style: AppTextStyles.caption(context)
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final isEmailLoading =
            state is AuthLoading && state.type == AuthLoadingType.email;
        final isGoogleLoading =
            state is AuthLoading && state.type == AuthLoadingType.google;
        final isWide = Breakpoints.isTablet(context);

        return AuthLayout(child: _FormCard(isWide: isWide, child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isWide) ...[
                Center(
                  child: Image.asset(
                    'assets/icons/AppIconNoBg.png',
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                AppStrings.signInHeadline,
                style: AppTextStyles.headline(context)
                    .copyWith(color: AppColors.textPrimary, height: 1.3),
                textAlign: isWide ? TextAlign.left : TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.signInSubHeadline,
                style: AppTextStyles.subtitle(context).copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: isWide ? TextAlign.left : TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => Validators.combine(v, [
                  (x) => Validators.required(x, fieldName: 'Email'),
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
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                ),
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    Validators.required(v, fieldName: 'Password'),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.forgotPassword),
                    child: Text(
                      AppStrings.forgotPassword,
                      style: const TextStyle(color: AppColors.brand),
                    ),
                  ),
                  Row(
                    spacing: 4,
                    children: [
                      Text(
                        AppStrings.alreadyHaveAccount,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.signUp),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: isEmailLoading ? null : _onSubmit,
                child: isEmailLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.signIn),
              ),
              const SizedBox(height: 24),
              AuthOptions(
                isLoading: isGoogleLoading,
                onGooglePressed: _onGoogleSignIn,
              ),
            ],
          ),
        )));
      },
    );
  }
}

class _FormCard extends StatelessWidget {
  final bool isWide;
  final Widget child;

  const _FormCard({required this.isWide, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!isWide) return child;
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
