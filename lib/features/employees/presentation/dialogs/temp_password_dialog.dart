import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/core/widgets/app_toast.dart';

/// Shown once, right after employee creation, when the credentials email
/// failed to send. This is the only chance the creator gets to see the
/// generated password — it is never persisted or shown again — so the sheet
/// is not dismissible except via the explicit "Done" button.
Future<void> showTempPasswordDialog({
  required BuildContext context,
  required String email,
  required String temporaryPassword,
}) {
  return showAppModal<void>(
    context: context,
    isDismissible: false,
    builder: (_) => _TempPasswordSheet(
      email: email,
      temporaryPassword: temporaryPassword,
    ),
  );
}

class _TempPasswordSheet extends StatelessWidget {
  final String email;
  final String temporaryPassword;

  const _TempPasswordSheet({
    required this.email,
    required this.temporaryPassword,
  });

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: temporaryPassword));
    AppToast.show(context, 'Copied', variant: AppToastVariant.info);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The password only exists in memory for this one screen — force the
      // explicit "Done" tap rather than letting a back-swipe lose it silently.
      canPop: false,
      child: AppBottomSheetScaffold(
        title: 'Employee Added',
        action: AppFilledButton(
          label: 'Done',
          onPressed: () => Navigator.of(context).pop(),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The credentials email couldn\'t be sent to $email.',
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'TEMPORARY PASSWORD',
                style: getOutfitStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        temporaryPassword,
                        style: getOutfitStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        IconlyLight.document,
                        size: 20,
                        color: AppColors.brand,
                      ),
                      tooltip: 'Copy',
                      onPressed: () => _copy(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share this with the employee securely — it will not be shown '
                'again.',
                style: getOutfitStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
