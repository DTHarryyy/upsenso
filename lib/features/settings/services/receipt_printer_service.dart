import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';

/// Generates a PDF receipt and sends it to the printer or share sheet.
/// Uses Noto Sans (via PdfGoogleFonts) so the ₱ peso sign and other
/// non-Latin glyphs render correctly — Helvetica/built-in fonts lack them.
class ReceiptPrinterService {
  const ReceiptPrinterService();

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> printReceipt({
    required ReceiptSettings settings,
    required String transactionId,
    required List<CartItem> items,
    required double subtotal,
    required double taxAmount,
    required double discountAmount,
    required double total,
    required double amountReceived,
    required double change,
    required String paymentMethod,
    required String cashierName,
    required String customerName,
    required DateTime dateTime,
    bool share = false,
  }) async {
    final bytes = await _buildPdf(
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
    );

    final name = 'receipt_${transactionId.substring(0, 8)}';

    if (share) {
      await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      if (settings.printDuplicateCopy) {
        await Printing.layoutPdf(
            onLayout: (_) async => bytes, name: '${name}_copy');
      }
    }
  }

  // ── PDF builder ───────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf({
    required ReceiptSettings settings,
    required String transactionId,
    required List<CartItem> items,
    required double subtotal,
    required double taxAmount,
    required double discountAmount,
    required double total,
    required double amountReceived,
    required double change,
    required String paymentMethod,
    required String cashierName,
    required String customerName,
    required DateTime dateTime,
  }) async {
    // ── Load Unicode-capable fonts (covers ₱ and all Latin scripts) ──────
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final fonts = _Fonts(regular: regular, bold: bold);

    final doc = pw.Document();

    final paperWidth = settings.paperSize == '58mm'
        ? PdfPageFormat(58 * PdfPageFormat.mm, double.infinity,
            marginAll: 3 * PdfPageFormat.mm)
        : PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
            marginAll: 4 * PdfPageFormat.mm);

    final baseFs = switch (settings.fontSize) {
      'small' => 7.0,
      'large' => 10.0,
      _ => 8.5,
    };

    final align = switch (settings.textAlignment) {
      'left' => pw.TextAlign.left,
      'right' => pw.TextAlign.right,
      _ => pw.TextAlign.center,
    };

    pw.ImageProvider? logoImage;
    if (settings.showLogo) logoImage = await _loadLogo(settings);

    final currency = settings.currencySymbol;

    doc.addPage(
      pw.Page(
        pageFormat: paperWidth,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Logo ────────────────────────────────────────────────
            if (logoImage != null) ...[
              pw.Center(child: pw.Image(logoImage, height: 50)),
              pw.SizedBox(height: 6),
            ],

            // ── Header text ──────────────────────────────────────────
            if (settings.headerText.isNotEmpty) ...[
              _text(settings.headerText, baseFs - 0.5, fonts,
                  align: align, color: PdfColors.grey600),
              pw.SizedBox(height: 3),
            ],

            // ── Business info ────────────────────────────────────────
            if (settings.businessName.isNotEmpty)
              _text(settings.businessName, baseFs + 2, fonts,
                  bold: true, align: align),
            if (settings.storeName.isNotEmpty)
              _text(settings.storeName, baseFs, fonts, align: align),
            if (settings.address.isNotEmpty)
              _text(settings.address, baseFs - 0.5, fonts,
                  align: align, color: PdfColors.grey600),
            if (settings.contactNumber.isNotEmpty)
              _text('Tel: ${settings.contactNumber}', baseFs - 0.5, fonts,
                  align: align, color: PdfColors.grey600),
            if (settings.email.isNotEmpty)
              _text(settings.email, baseFs - 0.5, fonts,
                  align: align, color: PdfColors.grey600),
            if (settings.tinNumber.isNotEmpty)
              _text('TIN: ${settings.tinNumber}', baseFs - 0.5, fonts,
                  align: align, color: PdfColors.grey600),

            _divider(fonts, baseFs),

            // ── Transaction meta ─────────────────────────────────────
            if (settings.showOrderId)
              _metaRow(
                  'Invoice #:',
                  transactionId.length > 8
                      ? transactionId.substring(0, 8).toUpperCase()
                      : transactionId,
                  baseFs,
                  fonts),
            if (settings.showDateTime)
              _metaRow('Date:', _fmtDate(dateTime), baseFs, fonts),
            if (settings.showCashierName && cashierName.isNotEmpty)
              _metaRow('Cashier:', cashierName, baseFs, fonts),
            if (settings.showCustomerName && customerName.isNotEmpty)
              _metaRow('Customer:', customerName, baseFs, fonts),
            _metaRow('Payment:', _fmtPayment(paymentMethod), baseFs, fonts),

            _divider(fonts, baseFs),

            // ── Items ────────────────────────────────────────────────
            ...items.map((i) => _itemRow(i, baseFs, currency, fonts)),

            _solidDivider(),

            // ── Totals ───────────────────────────────────────────────
            _totalRow('Subtotal', _fmt(subtotal, currency), baseFs, fonts),
            if (discountAmount > 0)
              _totalRow('Discount', '- ${_fmt(discountAmount, currency)}',
                  baseFs, fonts,
                  color: PdfColors.red700),
            if (settings.showTaxBreakdown && taxAmount > 0)
              _totalRow(
                  settings.vatInclusive ? 'VAT (incl.)' : 'VAT',
                  _fmt(taxAmount, currency),
                  baseFs,
                  fonts,
                  color: PdfColors.grey600),
            _totalRow(
                'TOTAL', _fmt(total, currency), baseFs + 1.5, fonts,
                bold: true),
            if (amountReceived > 0 && paymentMethod == 'cash') ...[
              _totalRow('Cash Received', _fmt(amountReceived, currency),
                  baseFs, fonts),
              _totalRow('Change', _fmt(change, currency), baseFs, fonts,
                  color: PdfColors.green700, bold: true),
            ],

            if (settings.vatInclusive && taxAmount > 0) ...[
              pw.SizedBox(height: 3),
              _text('(VAT inclusive)', baseFs - 1.5, fonts,
                  align: pw.TextAlign.center, color: PdfColors.grey500),
            ],

            _divider(fonts, baseFs),

            // ── Footer ───────────────────────────────────────────────
            if (settings.footerText.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              _text(settings.footerText, baseFs, fonts,
                  bold: true, align: pw.TextAlign.center),
            ],
            if (settings.returnPolicy.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              _text(settings.returnPolicy, baseFs - 1, fonts,
                  align: pw.TextAlign.center, color: PdfColors.grey600),
            ],
            if (settings.customNotes.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              _text(settings.customNotes, baseFs - 1, fonts,
                  align: pw.TextAlign.center, color: PdfColors.grey600),
            ],
            pw.SizedBox(height: 4),
            _text('* * *', baseFs - 1, fonts,
                align: pw.TextAlign.center, color: PdfColors.grey400),
            pw.SizedBox(height: 8),
          ],
        ),
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  // ── Logo loader ───────────────────────────────────────────────────────────

  Future<pw.ImageProvider?> _loadLogo(ReceiptSettings s) async {
    try {
      if (s.logoLocalPath.isNotEmpty && !kIsWeb) {
        final file = File(s.logoLocalPath);
        if (await file.exists()) return pw.MemoryImage(await file.readAsBytes());
      }
      if (s.logoUrl.isNotEmpty) return await networkImage(s.logoUrl);
    } catch (_) {}
    return null;
  }

  // ── PDF widget helpers ────────────────────────────────────────────────────

  /// All text goes through here so the font is always set — never falls back
  /// to Helvetica which lacks ₱.
  pw.Widget _text(
    String text,
    double fontSize,
    _Fonts fonts, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) =>
      pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: bold ? fonts.bold : fonts.regular,
          fontSize: fontSize,
          color: color,
        ),
      );

  pw.Widget _divider(_Fonts fonts, double baseFs) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: _text('- ' * 40, 6, fonts, color: PdfColors.grey400),
      );

  pw.Widget _solidDivider() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Divider(color: PdfColors.grey400, thickness: 0.5),
      );

  pw.Widget _metaRow(String label, String value, double fs, _Fonts fonts) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _text(label, fs - 1, fonts, color: PdfColors.grey600),
            _text(value, fs - 1, fonts, bold: true),
          ],
        ),
      );

  pw.Widget _itemRow(
      CartItem item, double fs, String currency, _Fonts fonts) {
    final qty = item.qty % 1 == 0
        ? item.qty.toInt().toString()
        : item.qty.toStringAsFixed(2);
    final label = item.variant.isEmpty || item.variant == 'Default'
        ? item.name
        : '${item.name} (${item.variant})';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(child: _text(label, fs, fonts)),
              _text(_fmt(item.total, currency), fs, fonts, bold: true),
            ],
          ),
          _text('  $qty x ${_fmt(item.unitPrice, currency)}', fs - 1.5, fonts,
              color: PdfColors.grey500),
        ],
      ),
    );
  }

  pw.Widget _totalRow(
    String label,
    String value,
    double fs,
    _Fonts fonts, {
    bool bold = false,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _text(label, fs, fonts, bold: bold, color: color),
            _text(value, fs, fonts, bold: bold, color: color),
          ],
        ),
      );

  // ── Formatters ────────────────────────────────────────────────────────────

  String _fmt(double v, String currency) {
    if (v >= 1_000_000) {
      return '$currency${(v / 1_000_000).toStringAsFixed(2)}M';
    }
    return '$currency${v.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'),
          (m) => '${m[1]},',
        )}';
  }

  String _fmtDate(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day}/${dt.year} ${pad(dt.hour)}:${pad(dt.minute)}';
  }

  String _fmtPayment(String method) => switch (method.toLowerCase()) {
        'cash' => 'Cash',
        'card' => 'Card',
        'gcash' => 'GCash',
        'maya' => 'Maya',
        _ => method,
      };
}

// ── Font holder ───────────────────────────────────────────────────────────────

class _Fonts {
  final pw.Font regular;
  final pw.Font bold;
  const _Fonts({required this.regular, required this.bold});
}
