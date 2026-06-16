import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/validators.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/auth/presentation/widgets/auth_layout.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) => Validators.combine(value, [
    (x) => Validators.required(x, fieldName: 'Password'),
    (x) => Validators.strongPassword(x, min: 8),
  ]);

  String? _validateConfirmPassword(String? value) =>
      Validators.combine(value, [
        (x) => Validators.required(x, fieldName: 'Confirm Password'),
        (x) => Validators.confirmPassword(x, _passwordController.text),
      ]);

  void _onSubmit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    context.read<AuthBloc>().add(
      AuthResetPasswordRequested(_passwordController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is! AuthLoading,
      listener: (context, state) {
        if (state is AuthPasswordResetSuccess) {
          AppToast.show(
            context,
            'Password reset',
            subtitle: 'You can now sign in with your new password.',
          );
          context.go(AppRoutes.signIn);
        } else if (state is AuthError) {
          AppToast.show(
            context,
            'Failed',
            subtitle: state.message,
            variant: AppToastVariant.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final pw = _passwordController.text;

        return AuthLayout(
          onBack: () => context.go(AppRoutes.signIn),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    IconlyLight.password,
                    size: 26,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 24),

                // Heading
                Text(
                  'Create new password',
                  style: AppTextStyles.headline(context).copyWith(
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your new password must be different from previously used passwords.',
                  style: AppTextStyles.subtitle(context).copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),

                // New password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  validator: _validatePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'New password',
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
                ),
                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmPassword,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _onSubmit(),
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
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
                ),
                const SizedBox(height: 16),

                // Password requirements
                _PasswordRequirements(password: pw),
                const SizedBox(height: 24),

                // Submit
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
                      : const Text('Reset password'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Password requirements checklist ───────────────────────────────────────

class _PasswordRequirements extends StatelessWidget {
  final String password;

  static final RegExp _hasUpper = RegExp(r'[A-Z]');
  static final RegExp _hasLower = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/]');

  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements',
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _Req(text: 'At least 8 characters', met: password.length >= 8),
          _Req(
            text: 'One uppercase letter',
            met: _hasUpper.hasMatch(password),
          ),
          _Req(
            text: 'One lowercase letter',
            met: _hasLower.hasMatch(password),
          ),
          _Req(text: 'One number', met: _hasDigit.hasMatch(password)),
          _Req(
            text: 'One special character',
            met: _hasSpecial.hasMatch(password),
          ),
        ],
      ),
    );
  }
}

class _Req extends StatelessWidget {
  final String text;
  final bool met;

  const _Req({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            met ? IconlyBold.tick_square : Icons.radio_button_unchecked,
            size: 15,
            color: met ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.caption(context).copyWith(
              color: met ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
