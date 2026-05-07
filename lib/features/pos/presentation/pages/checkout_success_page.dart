import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/settings/data/receipt_settings_repository.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';
import 'package:pos/features/settings/services/receipt_printer_service.dart';

class CheckoutSuccessPage extends StatefulWidget {
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

  @override
  State<CheckoutSuccessPage> createState() => _CheckoutSuccessPageState();
}

class _CheckoutSuccessPageState extends State<CheckoutSuccessPage> {
  bool _printing = false;
  bool _autoPrinted = false;

  bool get _isCash => widget.paymentMethod == 'cash';

  @override
  void initState() {
    super.initState();
    // Auto-print after a short delay so the success animation shows first
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoPrint());
  }

  Future<void> _maybeAutoPrint() async {
    if (_autoPrinted) return;
    final settings = await _loadSettings();
    if (settings == null || !settings.autoPrintAfterCheckout) return;
    _autoPrinted = true;
    if (mounted) await _doPrint(settings: settings);
  }

  Future<ReceiptSettings?> _loadSettings() async {
    try {
      return await sl<ReceiptSettingsRepository>().get(widget.businessId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _doPrint({ReceiptSettings? settings, bool share = false}) async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      final s = settings ?? await _loadSettings();
      if (s == null) {
        if (mounted) {
          StatusSnack.show(
            context,
            type: StatusType.warning,
            message: 'No receipt settings found. Configure them in Settings.',
          );
        }
        return;
      }
      await const ReceiptPrinterService().printReceipt(
        settings: s,
        transactionId: widget.transactionId,
        items: widget.items,
        subtotal: widget.subtotal,
        taxAmount: widget.taxAmount,
        discountAmount: widget.discountAmount,
        total: widget.total,
        amountReceived: widget.amountReceived,
        change: widget.change,
        paymentMethod: widget.paymentMethod,
        cashierName: widget.cashierName,
        customerName: widget.customerName,
        dateTime: widget.dateTime,
        share: share,
      );
    } catch (e) {
      if (mounted) {
        StatusSnack.show(
          context,
          type: StatusType.error,
          message: 'Print failed: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

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
            if (widget.customerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.customerName,
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              AppFormatters.currency(widget.total),
              style: getOutfitStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.itemCount} ${widget.itemCount == 1 ? 'item' : 'items'}',
              style: AppTextStyles.body(
                context,
              ).copyWith(color: AppColors.textMuted),
            ),

            // ── Cash change summary ───────────────────────────────────────
            if (_isCash) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _ChangeRow(
                        label: 'Received',
                        value: AppFormatters.currency(widget.amountReceived),
                        valueColor: AppColors.textPrimary,
                      ),
                      const Divider(height: 16, color: AppColors.borderSoft),
                      _ChangeRow(
                        label: 'Change',
                        value: AppFormatters.currency(widget.change),
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
                  // Print receipt
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _printing ? null : () => _doPrint(),
                      icon: _printing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brand,
                              ),
                            )
                          : const Icon(Icons.print_rounded, size: 18),
                      label: Text(
                        _printing ? 'Preparing...' : 'Print Receipt',
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
                  const SizedBox(height: 8),

                  // Share as PDF
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _printing ? null : () => _doPrint(share: true),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(
                        'Share Receipt',
                        style: getOutfitStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.borderSoft),
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
