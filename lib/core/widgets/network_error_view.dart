import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_filled_button.dart';

/// Which connection-loss animation to show. [lost] implies the device was
/// online and dropped; [none] implies there was never a connection to lose.
enum NetworkErrorKind { none, lost }

/// Full-screen (or embeddable) network-failure state with the project's
/// connection Lottie animations — the one place CLAUDE.md's "network errors
/// show the appropriate lottie, not just a snackbar" rule is implemented, so
/// every feature reuses it instead of a bespoke icon+text error block.
class NetworkErrorView extends StatelessWidget {
  final NetworkErrorKind kind;
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  const NetworkErrorView({
    super.key,
    this.kind = NetworkErrorKind.none,
    this.title = 'No internet connection',
    this.message = 'Check your connection and try again.',
    this.onRetry,
  });

  String get _asset => kind == NetworkErrorKind.lost
      ? 'assets/lotties/Lost Connection.json'
      : 'assets/lotties/No Connection.json';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 180,
              child: Lottie.asset(_asset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: getOutfitStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: getOutfitStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: AppFilledButton(label: 'Retry', onPressed: onRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// True when [message] (from [AppErrorMapper.message]) describes a
/// connectivity failure rather than some other kind of error — used to
/// decide whether a feature's error state should show [NetworkErrorView]
/// instead of a generic error block.
bool isNetworkErrorMessage(String message) {
  final lower = message.toLowerCase();
  return lower.contains("you're offline") ||
      lower.contains('timed out') ||
      lower.contains('connection');
}
