import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/core/widgets/widgets.dart';

class CheckoutSuccessPage extends StatelessWidget {
  final double total;
  final double amountReceived;
  final double change;
  final String paymentMethod;
  final String customerName;
  final int itemCount;

  const CheckoutSuccessPage({
    super.key,
    required this.total,
    required this.amountReceived,
    required this.change,
    required this.paymentMethod,
    this.customerName = '',
    required this.itemCount,
  });

  bool get _isCash => paymentMethod == 'cash';

  String _fmt(double v) => '₱${v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'),
        (m) => '${m[1]},',
      )}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // ── Lottie animation ─────────────────────────────────────────
            Lottie.asset(
              'assets/lotties/Action completed with confetti.json',
              width: 220,
              repeat: false,
            ),
            const SizedBox(height: 4),

            // ── Heading ──────────────────────────────────────────────────
            Text(
              'Payment Successful!',
              style: AppTextStyles.headline(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (customerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                customerName,
                style: AppTextStyles.body(context)
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              _fmt(total),
              style: getOutfitStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
              style: AppTextStyles.body(context)
                  .copyWith(color: AppColors.textMuted),
            ),

            // ── Cash change summary ───────────────────────────────────────
            if (_isCash) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _ChangeRow(
                        label: 'Received',
                        value: _fmt(amountReceived),
                        valueColor: AppColors.textPrimary,
                      ),
                      const Divider(
                          height: 16, color: AppColors.borderSoft),
                      _ChangeRow(
                        label: 'Change',
                        value: _fmt(change),
                        valueColor: AppColors.success,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // ── Buttons ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        StatusSnack.show(
                          context,
                          type: StatusType.info,
                          message: 'Printing not available yet',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        side: const BorderSide(color: AppColors.brand),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Print Receipt',
                        style: getOutfitStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppFilledButton(
                    label: 'New Sale',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  const _ChangeRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body(context)
              .copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: getOutfitStyle(
            color: valueColor,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
