import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:pos/app_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/settings/data/receipt_settings_repository.dart';
import 'package:pos/features/settings/services/receipt_printer_service.dart';

class CheckoutSuccessPage extends StatefulWidget {
  final String transactionId;
  final String invoiceNumber;
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
  final String? branchName;

  const CheckoutSuccessPage({
    super.key,
    required this.transactionId,
    required this.invoiceNumber,
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
    this.branchName,
  });

  @override
  State<CheckoutSuccessPage> createState() => _CheckoutSuccessPageState();
}

class _CheckoutSuccessPageState extends State<CheckoutSuccessPage> {
  bool _autoPrinting = false;

  @override
  void initState() {
    super.initState();
    _triggerAutoPrint();
  }

  Future<void> _triggerAutoPrint() async {
    try {
      var settings =
          await sl<ReceiptSettingsRepository>().get(widget.businessId);
      if (!mounted || settings == null) return;
      if (widget.branchName != null && widget.branchName!.isNotEmpty) {
        settings = settings.copyWith(storeName: widget.branchName);
      }
      if (!settings.autoPrintAfterCheckout) return;
      // Only auto-print to thermal — never pop the OS dialog automatically.
      if (!settings.thermalPrinterEnabled) return;
      final printerUrl = await ReceiptPrinterService.loadPrinterUrl();
      if (printerUrl.isEmpty) return;

      if (mounted) setState(() => _autoPrinting = true);
      await const ReceiptPrinterService().printReceipt(
        settings: settings,
        transactionId: widget.transactionId,
        invoiceNumber: widget.invoiceNumber,
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
      );
    } catch (e, st) {
      debugPrint('[CheckoutSuccessPage] Auto-print error: $e\n$st');
      if (mounted) {
        AppToast.show(
          context,
          'Auto-print failed',
          subtitle: 'Tap "Print Receipt" to try manually.',
          variant: AppToastVariant.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _autoPrinting = false);
    }
  }

  void _openPreview(BuildContext context) {
    context.push(
      AppRoutes.receiptPreview,
      extra: ReceiptPreviewArgs(
        transactionId: widget.transactionId,
        invoiceNumber: widget.invoiceNumber,
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
        businessId: widget.businessId,
        branchName: widget.branchName,
      ),
    );
  }

  bool get _isCash => widget.paymentMethod == 'cash';

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
              // Print receipt → navigates to preview page first
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openPreview(context),
                  icon: _autoPrinting
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
                    _autoPrinting ? 'Printing…' : 'Print Receipt',
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
