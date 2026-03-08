import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

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
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
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

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});

    if (_isComplete) {
      _verifyCode();
    }
  }

  void _fillFromPaste(String pastedText) {
    final digitsOnly = pastedText.replaceAll(RegExp(r'\D'), '');
    final chars = digitsOnly.split('');

    for (var i = 0; i < _codeLength && i < chars.length; i++) {
      _controllers[i].text = chars[i];
    }

    if (chars.length >= _codeLength) {
      _focusNodes[_codeLength - 1].requestFocus();
      setState(() {});
      _verifyCode();
    } else if (chars.isNotEmpty) {
      final nextIndex = chars.length.clamp(0, _codeLength - 1);
      _focusNodes[nextIndex].requestFocus();
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is! AuthLoading,
      listener: (context, state) {
        if (state is AuthResetCodeVerified) {
          StatusSnack.show(
            context,
            type: StatusType.success,
            title: 'Code verified',
            message: 'Please enter your new password.',
          );
          context.go('${AppRoutes.resetPassword}?email=${state.email}');
        } else if (state is AuthError) {
          StatusSnack.show(
            context,
            type: StatusType.error,
            title: 'Verification failed',
            message: state.message,
          );

          // Clear code on error
          for (final controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
          setState(() {});
        } else if (state is AuthResetCodeSent) {
          StatusSnack.show(
            context,
            type: StatusType.success,
            title: 'Code resent',
            message: 'A new 6-digit code has been sent to your email.',
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.go(AppRoutes.forgotPassword),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.brand.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          size: 40,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Check Your Email',
                        style: AppTextStyles.title(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.body(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                          children: [
                            const TextSpan(
                              text: 'We\'ve sent a 6-digit code to\n',
                            ),
                            TextSpan(
                              text: widget.email,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // OTP Input Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_codeLength, (index) {
                          return _buildCodeBox(index);
                        }),
                      ),
                      const SizedBox(height: 32),

                      // Resend Code
                      Center(
                        child: TextButton(
                          onPressed: isLoading ? null : _resendCode,
                          child: Text(
                            'Didn\'t receive the code? Resend',
                            style: AppTextStyles.body(context).copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Verify Button
                      FilledButton(
                        onPressed: _isComplete && !isLoading
                            ? _verifyCode
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: AppColors.brand.withAlpha(
                            100,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Verify Code',
                                style: AppTextStyles.subtitle(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
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

  Widget _buildCodeBox(int index) {
    return SizedBox(
      width: 50,
      height: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTextStyles.title(
          context,
        ).copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderSoft, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.brand, width: 2),
          ),
        ),
        onChanged: (value) => _onDigitChanged(index, value),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}
