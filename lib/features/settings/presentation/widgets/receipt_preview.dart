import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';

/// Live receipt preview that mirrors exactly what will be printed.
/// Pass real transaction data to show actual receipt; omit for sample placeholder values.
class ReceiptPreview extends StatelessWidget {
  final ReceiptSettings settings;

  final String? transactionId;
  final String? invoiceNumber;
  final List<CartItem>? items;
  final double? subtotal;
  final double? taxAmount;
  final double? discountAmount;
  final double? total;
  final double? amountReceived;
  final double? change;
  final String? paymentMethod;
  final String? cashierName;
  final String? customerName;
  final DateTime? dateTime;

  /// When true the body renders without its own card shell — parent provides it.
  final bool bare;

  const ReceiptPreview({
    super.key,
    required this.settings,
    this.transactionId,
    this.invoiceNumber,
    this.items,
    this.subtotal,
    this.taxAmount,
    this.discountAmount,
    this.total,
    this.amountReceived,
    this.change,
    this.paymentMethod,
    this.cashierName,
    this.customerName,
    this.dateTime,
    this.bare = false,
  });

  @override
  Widget build(BuildContext context) {
    // 58mm ≈ 200 logical px, 80mm ≈ 280. Used only in the non-bare (settings preview) card.
    final paperWidth = settings.paperSize == '58mm' ? 210.0 : 290.0;

    final baseFontSize = switch (settings.fontSize) {
      'small' => 11.0,
      'large' => 13.5,
      _ => 12.0,
    };
    final align = switch (settings.textAlignment) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };

    final body = _ReceiptBody(
      settings: settings,
      baseFontSize: baseFontSize,
      align: align,
      transactionId: transactionId,
      invoiceNumber: invoiceNumber,
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
    );

    if (bare) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        child: body,
      );
    }

    // Constrained to realistic paper width — same card used in both settings preview and print page
    return Center(
      child: Container(
        width: paperWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(14),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: body,
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  final ReceiptSettings settings;
  final double baseFontSize;
  final TextAlign align;

  final String? transactionId;
  final String? invoiceNumber;
  final List<CartItem>? items;
  final double? subtotal;
  final double? taxAmount;
  final double? discountAmount;
  final double? total;
  final double? amountReceived;
  final double? change;
  final String? paymentMethod;
  final String? cashierName;
  final String? customerName;
  final DateTime? dateTime;

  const _ReceiptBody({
    required this.settings,
    required this.baseFontSize,
    required this.align,
    this.transactionId,
    this.invoiceNumber,
    this.items,
    this.subtotal,
    this.taxAmount,
    this.discountAmount,
    this.total,
    this.amountReceived,
    this.change,
    this.paymentMethod,
    this.cashierName,
    this.customerName,
    this.dateTime,
  });

  bool get _isReal => transactionId != null;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    const currency = '₱';

    final displaySubtotal = subtotal ?? 415.0;
    final displayTotal = total ?? 415.0;
    final displayDiscount = discountAmount ?? 0.0;
    final displayTax = taxAmount ?? 0.0;
    final displayReceived = amountReceived ?? 500.0;
    final displayChange = change ?? 85.0;
    final displayPayment = _fmtPayment(paymentMethod ?? 'cash');
    final displayDate = _fmtDate(dateTime ?? DateTime.now());
    final displayInvoice = invoiceNumber ?? (transactionId != null
        ? transactionId!.substring(0, 8).toUpperCase()
        : 'INV-000001');
    final displayCashier =
        cashierName?.isNotEmpty == true ? cashierName! : 'Sample Cashier';
    final displayCustomer =
        customerName?.isNotEmpty == true ? customerName! : 'Walk-in Customer';
    final isCash = (paymentMethod ?? 'cash').toLowerCase() == 'cash';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Logo ──────────────────────────────────────────────────────────
        if (s.showLogo && _hasLogo(s)) ...[
          Center(child: _LogoWidget(settings: s)),
          const SizedBox(height: 10),
        ],

        // ── Header text ───────────────────────────────────────────────────
        if (s.headerText.isNotEmpty) ...[
          _line(s.headerText, baseFontSize - 1, align, color: Colors.black45),
          const SizedBox(height: 6),
        ],

        // ── Business info ─────────────────────────────────────────────────
        if (s.businessName.isNotEmpty) ...[
          _line(s.businessName, baseFontSize + 5, align,
              bold: true, color: const Color(0xFF0D1B3E)),
          const SizedBox(height: 2),
        ],
        if (s.storeName.isNotEmpty)
          _line(s.storeName, baseFontSize + 0.5, align,
              color: Colors.black54),
        if (s.address.isNotEmpty) ...[
          const SizedBox(height: 1),
          _line(s.address, baseFontSize - 0.5, align, color: Colors.black38),
        ],
        if (s.contactNumber.isNotEmpty)
          _line('Tel: ${s.contactNumber}', baseFontSize - 0.5, align,
              color: Colors.black38),
        if (s.email.isNotEmpty)
          _line(s.email, baseFontSize - 0.5, align, color: Colors.black38),
        if (s.website.isNotEmpty)
          _line(s.website, baseFontSize - 0.5, align, color: Colors.black38),
        if (s.tinNumber.isNotEmpty)
          _line('TIN: ${s.tinNumber}', baseFontSize - 0.5, align,
              color: Colors.black38),

        _dottedDivider(),

        // ── Order meta ────────────────────────────────────────────────────
        if (s.showOrderId)
          _metaRow('Invoice #:', displayInvoice, baseFontSize),
        if (s.showDateTime)
          _metaRow('Date:', displayDate, baseFontSize),
        if (s.showCashierName)
          _metaRow('Cashier:', displayCashier, baseFontSize),
        if (s.showCustomerName)
          _metaRow('Customer:', displayCustomer, baseFontSize),
        _metaRow('Payment:', displayPayment, baseFontSize),

        _dottedDivider(),

        // ── Items ─────────────────────────────────────────────────────────
        if (_isReal && items != null)
          ...items!.map((item) => _cartItemRow(item, currency, baseFontSize))
        else ...[
          _sampleItemRow('Product A', 2, 60.0, currency, baseFontSize),
          _sampleItemRow('Product B', 1, 85.0, currency, baseFontSize),
          _sampleItemRow('Product C', 3, 70.0, currency, baseFontSize),
        ],

        _solidDivider(),

        // ── Totals ────────────────────────────────────────────────────────
        _totalRow('Subtotal', _fmt(displaySubtotal, currency), baseFontSize),
        if (displayDiscount > 0)
          _totalRow(
            'Discount',
            '- ${_fmt(displayDiscount, currency)}',
            baseFontSize,
            color: Colors.red.shade600,
          ),
        if (s.showTaxBreakdown && displayTax > 0)
          _totalRow(
            'VAT (incl.)',
            _fmt(displayTax, currency),
            baseFontSize,
            color: Colors.black45,
          ),
        const SizedBox(height: 2),
        _totalRow(
          'TOTAL',
          _fmt(displayTotal, currency),
          baseFontSize + 2,
          bold: true,
          color: const Color(0xFF0D1B3E),
        ),
        if (isCash) ...[
          const SizedBox(height: 1),
          _totalRow(
            'Cash Tendered',
            _fmt(displayReceived, currency),
            baseFontSize,
            color: Colors.black54,
          ),
          _totalRow(
            'Change',
            _fmt(displayChange, currency),
            baseFontSize,
            bold: true,
            color: AppColors.success,
          ),
        ],

        _dottedDivider(),

        // ── Footer ────────────────────────────────────────────────────────
        if (s.footerText.isNotEmpty) ...[
          const SizedBox(height: 2),
          _line(s.footerText, baseFontSize + 0.5, align,
              bold: true, color: Colors.black87),
        ],
        if (s.returnPolicy.isNotEmpty) ...[
          const SizedBox(height: 4),
          _line(s.returnPolicy, baseFontSize - 1, align, color: Colors.black38),
        ],
        if (s.customNotes.isNotEmpty) ...[
          const SizedBox(height: 4),
          _line(s.customNotes, baseFontSize - 1, align, color: Colors.black38),
        ],
        if (s.showQrCode) ...[
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(painter: _QrPainter()),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        _line('* * *', baseFontSize, TextAlign.center, color: Colors.black26),
        // Tear-off gap so the preview matches the extra feed lines on the printer
        const SizedBox(height: 20),
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _TearLinePainter(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _hasLogo(ReceiptSettings s) =>
      s.logoLocalPath.isNotEmpty || s.logoUrl.isNotEmpty;

  Widget _cartItemRow(CartItem item, String currency, double size) {
    final qty = item.qty % 1 == 0
        ? item.qty.toInt().toString()
        : item.qty.toStringAsFixed(2);
    final label = item.variant.isEmpty || item.variant == 'Default'
        ? item.name
        : '${item.name} (${item.variant})';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: getOutfitStyle(
                        fontSize: size,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                const SizedBox(height: 1),
                Text(
                  '$qty x ${_fmt(item.unitPrice, currency)}',
                  style: getOutfitStyle(
                      fontSize: size - 1.5, color: Colors.black38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _fmt(item.total, currency),
            style: getOutfitStyle(
                fontSize: size,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _sampleItemRow(
      String name, int qty, double unitPrice, String currency, double size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: getOutfitStyle(
                        fontSize: size,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                const SizedBox(height: 1),
                Text(
                  '$qty x ${_fmt(unitPrice, currency)}',
                  style: getOutfitStyle(
                      fontSize: size - 1.5, color: Colors.black38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _fmt(qty * unitPrice, currency),
            style: getOutfitStyle(
                fontSize: size,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _line(String text, double size, TextAlign align,
      {bool bold = false, Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        textAlign: align,
        style: getOutfitStyle(
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color,
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value, double size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: getOutfitStyle(
                  fontSize: size - 0.5, color: Colors.black45)),
          const Spacer(),
          Text(value,
              style: getOutfitStyle(
                  fontSize: size - 0.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String amount, double size,
      {bool bold = false, Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: getOutfitStyle(
                  fontSize: size,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color)),
          const Spacer(),
          Text(amount,
              style: getOutfitStyle(
                  fontSize: size,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }

  Widget _dottedDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DashedLinePainter(),
        ),
      );

  Widget _solidDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
      );

  String _fmt(double v, String currency) {
    if (v >= 1000000) {
      return '$currency${(v / 1000000).toStringAsFixed(2)}M';
    }
    return '$currency${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
  }

  String _fmtDate(DateTime dt) =>
      '${dt.month}/${dt.day}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  String _fmtPayment(String method) => switch (method.toLowerCase()) {
        'cash' => 'Cash',
        'card' => 'Card',
        'gcash' => 'GCash',
        'maya' => 'Maya',
        _ => method,
      };
}

// ── QR code visual placeholder ────────────────────────────────────────────────

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cell = size.width / 21;

    // White background
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draws one QR finder pattern (7×7) at grid position (gc, gr)
    void finder(int gc, int gr) {
      for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 7; c++) {
          final onRing = r == 0 || r == 6 || c == 0 || c == 6;
          final onCore = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          paint.color = (onRing || onCore) ? Colors.black87 : Colors.white;
          canvas.drawRect(
            Rect.fromLTWH((gc + c) * cell, (gr + r) * cell, cell, cell),
            paint,
          );
        }
      }
    }

    finder(0, 0);   // top-left
    finder(14, 0);  // top-right
    finder(0, 14);  // bottom-left

    // Timing strips (row 6 and col 6, cols/rows 8–12)
    paint.color = Colors.black87;
    for (var i = 8; i <= 12; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * cell, 6 * cell, cell, cell), paint);
      canvas.drawRect(Rect.fromLTWH(6 * cell, i * cell, cell, cell), paint);
    }

    // Sparse data modules to fill the centre area
    const dots = [
      [9, 9], [9, 11], [9, 13], [10, 8], [10, 10], [10, 12], [10, 14],
      [11, 9], [11, 11], [11, 13], [12, 8], [12, 10], [12, 12],
      [13, 9], [13, 11], [8, 9], [8, 11], [8, 13],
      [9, 16], [9, 18], [10, 17], [10, 19], [11, 16], [11, 18],
      [12, 17], [12, 19], [13, 16], [16, 9], [16, 11],
      [17, 8], [17, 10], [18, 9], [18, 11], [19, 8], [19, 10],
    ];
    for (final d in dots) {
      canvas.drawRect(
        Rect.fromLTWH(d[0] * cell, d[1] * cell, cell, cell),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Tear-off line painter ─────────────────────────────────────────────────────

class _TearLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1.0;
    const dashW = 6.0;
    const gapW = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashW, 0), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Dashed divider painter ────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8D8D8)
      ..strokeWidth = 1.0;
    const dashWidth = 5.0;
    const gapWidth = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Logo widget ───────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  final ReceiptSettings settings;
  const _LogoWidget({required this.settings});

  @override
  Widget build(BuildContext context) {
    if (settings.logoLocalPath.isNotEmpty && !kIsWeb) {
      return Image.file(
        File(settings.logoLocalPath),
        height: 64,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => _urlFallback(),
      );
    }
    if (settings.logoUrl.isNotEmpty) return _urlFallback();
    return const SizedBox.shrink();
  }

  Widget _urlFallback() {
    if (settings.logoUrl.isEmpty) return const SizedBox.shrink();
    return Image.network(
      settings.logoUrl,
      height: 64,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) =>
          const Icon(IconlyLight.image, size: 40, color: Colors.black26),
    );
  }
}
