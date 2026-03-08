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

class VerificationPage extends StatefulWidget {
  final String email;

  const VerificationPage({super.key, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
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
  }

  void _fillFromPaste(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return;

    final chars = digitsOnly.split('').take(_codeLength).toList();
    for (var i = 0; i < _codeLength; i++) {
      _controllers[i].text = i < chars.length ? chars[i] : '';
    }

    final lastIndex = chars.length >= _codeLength
        ? _codeLength - 1
        : chars.length;
    _focusNodes[lastIndex].requestFocus();
    setState(() {});
  }

  void _verifyCode() {
    if (!_isComplete) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthVerifySignUpCodeRequested(widget.email, _enteredCode),
    );
  }

  void _resendCode() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthResendSignUpCodeRequested(widget.email));
  }

  Widget _buildCodeField(int index) {
    return SizedBox(
      width: 48,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        autofocus: index == 0,
        keyboardType: TextInputType.number,
        textInputAction: index == _codeLength - 1
            ? TextInputAction.done
            : TextInputAction.next,
        textAlign: TextAlign.center,
        style: AppTextStyles.title(
          context,
        ).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (value) => _onDigitChanged(index, value),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is! AuthLoading,
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.businessProfile);
          return;
        }

        if (state is AuthError) {
          StatusSnack.show(
            context,
            type: StatusType.error,
            title: 'Verification failed',
            message: state.message,
          );
          return;
        }

        if (state is AuthCodeSent && state.email == widget.email) {
          StatusSnack.show(
            context,
            type: StatusType.success,
            title: 'Code sent',
            message: 'A new 6-digit code has been sent to your email.',
          );
        }
      },
      builder: (context, state) {
        final isLoading =
            state is AuthLoading &&
            (state.type == AuthLoadingType.verifyCode ||
                state.type == AuthLoadingType.signUp);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.go(AppRoutes.signUp),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter verification code',
                          style: AppTextStyles.headline(
                            context,
                          ).copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We sent a 6-digit code to ${widget.email}.',
                          style: AppTextStyles.body(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_codeLength, _buildCodeField),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Didn\'t receive the code?',
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: isLoading ? null : _resendCode,
                          child: Text(
                            'Resend code',
                            style: AppTextStyles.body(context).copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isLoading || !_isComplete
                                ? null
                                : _verifyCode,
                            child: isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify code'),
                          ),
                        ),
                      ],
                    ),
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
