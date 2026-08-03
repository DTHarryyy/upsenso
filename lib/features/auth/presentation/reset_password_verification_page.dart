import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/auth/presentation/widgets/auth_layout.dart';
import 'package:pos/features/auth/presentation/widgets/resend_code_button.dart';

class ResetPasswordVerificationPage extends StatefulWidget {
  final String email;

  const ResetPasswordVerificationPage({super.key, required this.email});

  @override
  State<ResetPasswordVerificationPage> createState() =>
      _ResetPasswordVerificationPageState();
}

class _ResetPasswordVerificationPageState
    extends State<ResetPasswordVerificationPage> {
  static const int _codeLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(
      _codeLength,
      (index) => FocusNode(
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty &&
              index > 0) {
            _controllers[index - 1].clear();
            _focusNodes[index - 1].requestFocus();
            setState(() {});
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();
  bool get _isComplete => _enteredCode.length == _codeLength;

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      _fillFromPaste(value);
      return;
    }
    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
    if (_isComplete) _verifyCode();
  }

  void _fillFromPaste(String pastedText) {
    final digits = pastedText.replaceAll(RegExp(r'\D'), '');
    final chars = digits.split('');
    for (var i = 0; i < _codeLength && i < chars.length; i++) {
      _controllers[i].text = chars[i];
    }
    if (chars.length >= _codeLength) {
      _focusNodes[_codeLength - 1].requestFocus();
      setState(() {});
      _verifyCode();
    } else if (chars.isNotEmpty) {
      _focusNodes[chars.length.clamp(0, _codeLength - 1)].requestFocus();
      setState(() {});
    }
  }

  void _verifyCode() {
    if (!_isComplete) return;
    context.read<AuthBloc>().add(
      AuthVerifyResetCodeRequested(widget.email, _enteredCode),
    );
  }

  void _resendCode() {
    context.read<AuthBloc>().add(AuthResendResetCodeRequested(widget.email));
  }

  void _clearAndRefocus() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is! AuthLoading,
      listener: (context, state) {
        if (state is AuthResetCodeVerified) {
          AppToast.show(
            context,
            'Code verified',
            subtitle: 'Please enter your new password.',
          );
          context.go('${AppRoutes.resetPassword}?email=${state.email}');
        } else if (state is AuthError) {
          AppToast.show(
            context,
            'Verification failed',
            subtitle: state.message,
            variant: AppToastVariant.error,
          );
          _clearAndRefocus();
        } else if (state is AuthResetCodeSent) {
          AppToast.show(
            context,
            'Code resent',
            subtitle: 'A new 6-digit code has been sent to your email.',
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AuthLayout(
          onBack: () => context.go(AppRoutes.forgotPassword),
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
                  IconlyLight.message,
                  size: 26,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 24),

              // Heading
              Text(
                'Check your email',
                style: AppTextStyles.headline(context).copyWith(
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.subtitle(context).copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit reset code to '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  _codeLength,
                  (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    autofocus: i == 0,
                    isLast: i == _codeLength - 1,
                    onChanged: (v) => _onDigitChanged(i, v),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Verify button
              FilledButton(
                onPressed: isLoading || !_isComplete ? null : _verifyCode,
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
                    : const Text('Verify code'),
              ),
              const SizedBox(height: 20),

              // Resend
              ResendCodeButton(
                promptText: "Didn't receive it? ",
                label: 'Resend code',
                enabled: !isLoading,
                onResend: _resendCode,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── OTP digit box ──────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final bool isLast;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.isLast,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 60,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        keyboardType: TextInputType.number,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.brand, width: 2),
          ),
        ),
        onChanged: onChanged,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}
