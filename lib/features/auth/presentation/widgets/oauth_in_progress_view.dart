import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';

/// Shown while an OAuth provider redirect is in flight. Falls back to a
/// retry affordance if the redirect never comes back (e.g. the user
/// abandons the provider's account chooser without completing it).
class OAuthInProgressView extends StatefulWidget {
  final String provider;
  final String actionLabel;

  const OAuthInProgressView({
    super.key,
    required this.provider,
    required this.actionLabel,
  });

  @override
  State<OAuthInProgressView> createState() => _OAuthInProgressViewState();
}

class _OAuthInProgressViewState extends State<OAuthInProgressView> {
  static const _timeout = Duration(seconds: 25);

  Timer? _timer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerLabel = widget.provider == 'google' ? 'Google' : 'Facebook';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _timedOut
                ? _timeoutContent(context)
                : _progressContent(context, providerLabel),
          ),
        ),
      ),
    );
  }

  List<Widget> _progressContent(BuildContext context, String providerLabel) {
    return [
      const CircularProgressIndicator(),
      const SizedBox(height: 24),
      Text(
        'Completing $providerLabel ${widget.actionLabel}…',
        style: AppTextStyles.body(
          context,
        ).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 2),
      Text(
        'Please wait while we finish setting up your account',
        style: AppTextStyles.caption(
          context,
        ).copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    ];
  }

  List<Widget> _timeoutContent(BuildContext context) {
    return [
      const Icon(Icons.error_outline, color: AppColors.textSecondary),
      const SizedBox(height: 24),
      Text(
        'Taking longer than expected',
        style: AppTextStyles.body(
          context,
        ).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 2),
      Text(
        "We couldn't confirm your sign-in. Please return and try again.",
        style: AppTextStyles.caption(
          context,
        ).copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: () =>
            context.read<AuthBloc>().add(const AuthOAuthCancelled()),
        child: const Text('Return to sign in'),
      ),
    ];
  }
}
