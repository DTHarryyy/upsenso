import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/core/widgets/app_status_badge.dart';

/// One line of the refund summary shown for review before committing.
typedef RefundConfirmLine = ({String label, double qty, double amount, bool restock});

/// Final review step before [RefundService.refund] is actually called — a
/// refund is irreversible (money, inventory, and the audit trail all move
/// together), so this is the one explicit "are you sure" checkpoint in the
/// flow. Returns `true` only if the user taps "Confirm Refund".
Future<bool> showRefundConfirmSheet(
  BuildContext context, {
  required List<RefundConfirmLine> lines,
  required double total,
  String? reason,
}) async {
  final result = await showAppModal<bool>(
    context: context,
    forceDialog: true,
    builder: (_) => _RefundConfirmSheet(lines: lines, total: total, reason: reason),
  );
  return result ?? false;
}

class _RefundConfirmSheet extends StatelessWidget {
  final List<RefundConfirmLine> lines;
  final double total;
  final String? reason;

  const _RefundConfirmSheet({
    required this.lines,
    required this.total,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title: 'Confirm Refund',
      action: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.borderSoft),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: getOutfitStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppFilledButton(
              label: 'Confirm Refund',
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${AppFormatters.quantity(line.qty)} × ${line.label}',
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    if (!line.restock) ...[
                      AppStatusBadge(
                        label: 'Not restocked',
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      AppFormatters.currency(line.amount),
                      style: AppTextStyles.body(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (reason != null && reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Reason: $reason',
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 10),
            Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total refund',
                  style: AppTextStyles.subtitle(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  AppFormatters.currency(total),
                  style: AppTextStyles.money(
                    context,
                  ).copyWith(color: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppInlineBanner(
              message:
                  "This refunds the customer immediately and can't be undone.",
              variant: AppInlineBannerVariant.warning,
            ),
          ],
        ),
      ),
    );
  }
}
