import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/settings/data/receipt_settings_repository.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';
import 'package:pos/features/settings/presentation/widgets/receipt_preview.dart';
import 'package:pos/features/settings/presentation/widgets/receipt_settings_section.dart';
import 'package:pos/features/settings/services/receipt_printer_service.dart';

class ReceiptPreviewPage extends StatefulWidget {
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
  final DateTime dateTime;
  final String businessId;
  final String? branchName;

  const ReceiptPreviewPage({
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
    required this.customerName,
    required this.dateTime,
    required this.businessId,
    this.branchName,
  });

  @override
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage>
    with SingleTickerProviderStateMixin {
  ReceiptSettings? _settings;
  bool _loading = true;
  _ReceiptAction? _activeAction;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadSettings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      var s = await sl<ReceiptSettingsRepository>().get(widget.businessId);
      // Override storeName with the actual sale branch so the receipt
      // always shows where the sale happened, not the static setting.
      if (s != null && widget.branchName != null && widget.branchName!.isNotEmpty) {
        s = s.copyWith(storeName: widget.branchName);
      }
      if (mounted) {
        setState(() {
          _settings = s;
          _loading = false;
        });
        _fadeController.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(_ReceiptAction action) async {
    if (_activeAction != null) return;
    final s = _settings;
    if (s == null) {
      StatusSnack.show(
        context,
        type: StatusType.warning,
        message: 'No receipt settings found. Configure them in Settings.',
      );
      return;
    }

    if (action == _ReceiptAction.print && s.thermalPrinterEnabled) {
      var printerUrl = await ReceiptPrinterService.loadPrinterUrl();
      if (printerUrl.isEmpty && mounted) {
        // Show the printer setup dialog in-place — no navigation needed.
        // After the user connects a printer and closes the dialog, fall through
        // and print immediately if one was saved.
        await showDialog<void>(
          context: context,
          barrierColor: Colors.black.withAlpha(100),
          builder: (_) => const PrinterSetupDialog(),
        );
        printerUrl = await ReceiptPrinterService.loadPrinterUrl();
        if (printerUrl.isEmpty) return; // user closed without connecting
      }
    }

    setState(() => _activeAction = action);
    try {
      final service = const ReceiptPrinterService();
      final name = 'receipt_${widget.transactionId.substring(0, 8)}';

      if (action == _ReceiptAction.saveAsPdf ||
          action == _ReceiptAction.share) {
        final bytes = await service.buildPdf(
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
        );
        await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
      } else {
        await service.printReceipt(
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
        );
        if (mounted) {
          StatusSnack.show(
            context,
            type: StatusType.success,
            message: 'Sent to printer',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        StatusSnack.show(
          context,
          type: StatusType.error,
          message: 'Failed: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  void _openFullscreen() {
    if (_settings == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (context, a, b) => _FullscreenOverlay(
          settings: _settings!,
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
        ),
        transitionsBuilder: (context, anim, secondary, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return isWide ? _buildWide(context) : _buildNarrow(context);
      },
    );
  }

  // ── Narrow layout (phone) ───────────────────────────────────────────────────

  Widget _buildNarrow(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: _buildAppBar(context),
      body: _loading
          ? _buildLoader()
          : Column(
              children: [
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: _settings != null
                          ? ReceiptPreview(
                              settings: _settings!,
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
                            )
                          : Center(
                              child: _NoSettingsCard(
                                onConfigure: () =>
                                    context.push(AppRoutes.receiptSettings),
                              ),
                            ),
                    ),
                  ),
                ),
                _ActionBar(
                  activeAction: _activeAction,
                  hasPrinter: _settings?.thermalPrinterEnabled == true,
                  bottomPad: bottomPad,
                  onPrint: () => _act(_ReceiptAction.print),
                  onSavePdf: () => _act(_ReceiptAction.saveAsPdf),
                  onShare: () => _act(_ReceiptAction.share),
                ),
              ],
            ),
    );
  }

  // ── Wide layout (tablet / desktop) ─────────────────────────────────────────

  Widget _buildWide(BuildContext context) {
    final shortId = widget.transactionId.length > 8
        ? widget.transactionId.substring(0, 8).toUpperCase()
        : widget.transactionId.toUpperCase();
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(24, topPad + 12, 24, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF0D1B3E),
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Receipt Preview',
                        style: getOutfitStyle(
                          color: const Color(0xFF0D1B3E),
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '#$shortId',
                        style: getOutfitStyle(
                          color: Colors.black38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _openFullscreen,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.crop_free_rounded,
                      color: Color(0xFF0D1B3E),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEEEEE)),

          // ── Two-column body ───────────────────────────────────────────
          Expanded(
            child: _loading
                ? _buildLoader()
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: receipt paper on dark tinted background
                        Expanded(
                          flex: 55,
                          child: Container(
                            color: const Color(0xFFE8ECF2),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 40),
                              child: _settings != null
                                  ? ReceiptPreview(
                                      settings: _settings!,
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
                                    )
                                  : Center(
                                      child: _NoSettingsCard(
                                        onConfigure: () => context
                                            .push(AppRoutes.receiptSettings),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        // Divider
                        Container(
                            width: 1, color: const Color(0xFFE0E0E0)),

                        // Right: details + actions panel
                        SizedBox(
                          width: 300,
                          child: _DetailsPanel(
                            total: widget.total,
                            activeAction: _activeAction,
                            hasPrinter:
                                _settings?.thermalPrinterEnabled == true,
                            bottomPad: bottomPad,
                            onPrint: () => _act(_ReceiptAction.print),
                            onSavePdf: () => _act(_ReceiptAction.saveAsPdf),
                            onShare: () => _act(_ReceiptAction.share),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final shortId = widget.transactionId.length > 8
        ? widget.transactionId.substring(0, 8).toUpperCase()
        : widget.transactionId.toUpperCase();

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 56,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEEEEEE)),
      ),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0D1B3E),
                size: 15,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Receipt Preview',
                  style: getOutfitStyle(
                    color: const Color(0xFF0D1B3E),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '#$shortId',
                  style: getOutfitStyle(
                    color: Colors.black38,
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openFullscreen,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.crop_free_rounded,
                color: Color(0xFF0D1B3E),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.brand, strokeWidth: 2),
    );
  }
}

// ── Action types ──────────────────────────────────────────────────────────────

enum _ReceiptAction { print, saveAsPdf, share }

// ── Right-panel (wide layout only) ───────────────────────────────────────────

class _DetailsPanel extends StatelessWidget {
  final double total;
  final _ReceiptAction? activeAction;
  final bool hasPrinter;
  final double bottomPad;
  final VoidCallback onPrint;
  final VoidCallback onSavePdf;
  final VoidCallback onShare;

  const _DetailsPanel({
    required this.total,
    required this.activeAction,
    required this.hasPrinter,
    required this.bottomPad,
    required this.onPrint,
    required this.onSavePdf,
    required this.onShare,
  });

  String _fmt(double v) {
    const currency = '₱';
    if (v >= 1000000) return '$currency${(v / 1000000).toStringAsFixed(2)}M';
    return '$currency${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // ── Total hero ────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions',
                    style: getOutfitStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black38,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: getOutfitStyle(
                            fontSize: 12,
                            color: AppColors.brand,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fmt(total),
                          style: getOutfitStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
            child: Column(
              children: [
                _PrintButton(
                  loading: activeAction == _ReceiptAction.print,
                  disabled: activeAction != null,
                  hasPrinter: hasPrinter,
                  onTap: onPrint,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _GhostButton(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'Save PDF',
                        loading: activeAction == _ReceiptAction.saveAsPdf,
                        disabled: activeAction != null,
                        onTap: onSavePdf,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GhostButton(
                        icon: Icons.ios_share_rounded,
                        label: 'Share',
                        loading: activeAction == _ReceiptAction.share,
                        disabled: activeAction != null,
                        onTap: onShare,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action bar (narrow layout) ────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final _ReceiptAction? activeAction;
  final bool hasPrinter;
  final double bottomPad;
  final VoidCallback onPrint;
  final VoidCallback onSavePdf;
  final VoidCallback onShare;

  const _ActionBar({
    required this.activeAction,
    required this.hasPrinter,
    required this.bottomPad,
    required this.onPrint,
    required this.onSavePdf,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      child: Row(
        children: [
          _GhostButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Save PDF',
            loading: activeAction == _ReceiptAction.saveAsPdf,
            disabled: activeAction != null,
            onTap: onSavePdf,
          ),
          const SizedBox(width: 8),
          _GhostButton(
            icon: Icons.ios_share_rounded,
            label: 'Share',
            loading: activeAction == _ReceiptAction.share,
            disabled: activeAction != null,
            onTap: onShare,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PrintButton(
              loading: activeAction == _ReceiptAction.print,
              disabled: activeAction != null,
              hasPrinter: hasPrinter,
              onTap: onPrint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared buttons ────────────────────────────────────────────────────────────

class _PrintButton extends StatelessWidget {
  final bool loading;
  final bool disabled;
  final bool hasPrinter;
  final VoidCallback onTap;

  const _PrintButton({
    required this.loading,
    required this.disabled,
    required this.hasPrinter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled && !loading ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(13),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: AppColors.brand.withAlpha(72),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              else
                const Icon(Icons.print_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loading ? 'Printing…' : 'Print',
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (!loading)
                    Text(
                      hasPrinter ? 'Thermal printer' : 'No printer',
                      style: getOutfitStyle(
                        fontSize: 10,
                        color: Colors.white.withAlpha(170),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  const _GhostButton({
    required this.icon,
    required this.label,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled && !loading ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black45),
                )
              else
                Icon(icon, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                label,
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── No-settings fallback ──────────────────────────────────────────────────────

class _NoSettingsCard extends StatelessWidget {
  final VoidCallback onConfigure;
  const _NoSettingsCard({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 30, color: AppColors.brand),
          ),
          const SizedBox(height: 16),
          Text(
            'Receipt not configured',
            style: getOutfitStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D1B3E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your receipt settings to see a preview here.',
            textAlign: TextAlign.center,
            style: getOutfitStyle(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onConfigure,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Configure Receipt',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fullscreen blur overlay ───────────────────────────────────────────────────

class _FullscreenOverlay extends StatelessWidget {
  final ReceiptSettings settings;
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
  final DateTime dateTime;

  const _FullscreenOverlay({
    required this.settings,
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
    required this.customerName,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.black.withAlpha(120)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ReceiptPreview(
                        settings: settings,
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
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tap anywhere to close',
                        style: getOutfitStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
