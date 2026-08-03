import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

/// "Resend code" link with a 60s cooldown between taps, so users can't spam
/// the OTP endpoint. Cooldown starts as soon as this is shown (a code was
/// already sent to land the user here) and restarts on every tap.
class ResendCodeButton extends StatefulWidget {
  final String promptText;
  final String label;
  final bool enabled;
  final VoidCallback onResend;

  const ResendCodeButton({
    super.key,
    required this.promptText,
    required this.label,
    required this.onResend,
    this.enabled = true,
  });

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  static const _cooldown = Duration(seconds: 60);

  Timer? _timer;
  int _secondsLeft = _cooldown.inSeconds;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _handleTap() {
    if (_secondsLeft > 0 || !widget.enabled) return;
    widget.onResend();
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = widget.enabled && _secondsLeft == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.promptText,
          style: AppTextStyles.body(
            context,
          ).copyWith(color: AppColors.textSecondary, fontSize: 13),
        ),
        GestureDetector(
          onTap: canResend ? _handleTap : null,
          child: Text(
            canResend ? widget.label : 'Resend in ${_secondsLeft}s',
            style: AppTextStyles.body(context).copyWith(
              color: canResend ? AppColors.brand : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
