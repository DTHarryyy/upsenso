import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';
import 'package:pos/core/widgets/app_modal.dart';

/// Prompts for a manager PIN and runs [authorize] with it. [authorize] must
/// verify the PIN server-side and return an opaque authorization token; it
/// throws on a wrong/locked PIN. Returns the token on success, or `null` if the
/// user cancels. Generic on purpose — the caller supplies the verification, so
/// this widget never sees a hash and stays decoupled from any specific RPC.
Future<String?> showManagerPinSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Future<String> Function(String pin) authorize,
}) {
  return showAppModal<String>(
    context: context,
    forceDialog: true,
    builder: (_) =>
        _ManagerPinSheet(title: title, subtitle: subtitle, authorize: authorize),
  );
}

class _ManagerPinSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<String> Function(String pin) authorize;

  const _ManagerPinSheet({
    required this.title,
    required this.subtitle,
    required this.authorize,
  });

  @override
  State<_ManagerPinSheet> createState() => _ManagerPinSheetState();
}

class _ManagerPinSheetState extends State<_ManagerPinSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'Enter the 4–6 digit PIN.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await widget.authorize(pin);
      if (mounted) Navigator.pop(context, token);
    } catch (e, st) {
      debugPrint('[ManagerPinSheet] authorize failed: $e\n$st');
      final msg = e.toString();
      setState(() {
        _busy = false;
        _error = msg.contains('LOCKED')
            ? 'Too many attempts. Try again later.'
            : msg.contains('INVALID_PIN')
                ? 'Incorrect PIN.'
                : 'Could not authorize. Check your connection and try again.';
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title: widget.title,
      action: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.borderSoft),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Cancel', style: AppTextStyles.body(context)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppFilledButton(
              label: 'Authorize',
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subtitle,
              style: AppTextStyles.body(context)
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              onSubmitted: (_) => _submit(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.subtitle(context)
                  .copyWith(letterSpacing: 8, color: AppColors.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderSoft),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              AppInlineBanner(
                message: _error!,
                variant: AppInlineBannerVariant.error,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
