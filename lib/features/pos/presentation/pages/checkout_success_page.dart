import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:pos/app_router.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';

class CheckoutSuccessPage extends StatelessWidget {
  final String transactionId;
  final List<CartItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final double amountReceived;
  final double change;
  final String paymentMethod;
  final String cashierName;
  final String customerName;
  final int itemCount;
  final DateTime dateTime;
  final String businessId;

  const CheckoutSuccessPage({
    super.key,
    required this.transactionId,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.amountReceived,
    required this.change,
    required this.paymentMethod,
    required this.cashierName,
    this.customerName = '',
    required this.itemCount,
    required this.dateTime,
    required this.businessId,
  });

  void _openPreview(BuildContext context) {
    context.push(
      AppRoutes.receiptPreview,
      extra: ReceiptPreviewArgs(
        transactionId: transactionId,
        items: items,
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        total: total,
        amountReceived: amountReceived,
        change: change,
        paymentMethod: paymentMethod,
        cashierName: cashierName,
        customerName: customerName,
        dateTime: dateTime,
        businessId: businessId,
      ),
    );
  }

  bool get _isCash => paymentMethod == 'cash';

  @override
  Widget build(BuildContext context) {
    final isWide = Breakpoints.isTablet(context);
    final content = Column(
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
          style: AppTextStyles.headline(
            context,
          ).copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        if (customerName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            customerName,
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          AppFormatters.currency(total),
          style: getOutfitStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
          style: AppTextStyles.body(
            context,
          ).copyWith(color: AppColors.textMuted),
        ),

        // ── Cash change summary ───────────────────────────────────────
        if (_isCash) ...[
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ChangeRow(
                    label: 'Received',
                    value: AppFormatters.currency(amountReceived),
                    valueColor: AppColors.textPrimary,
                  ),
                  const Divider(height: 16, color: AppColors.borderSoft),
                  _ChangeRow(
                    label: 'Change',
                    value: AppFormatters.currency(change),
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
              // Print receipt → navigates to preview page first
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openPreview(context),
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: Text(
                    'Print Receipt',
                    style: getOutfitStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(color: AppColors.brand),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: content,
                ),
              )
            : content,
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
          style: AppTextStyles.body(
            context,
          ).copyWith(color: AppColors.textSecondary),
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
