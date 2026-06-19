import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';

/// Generates a PDF receipt and sends it to the printer or share sheet.
/// Uses Noto Sans (via PdfGoogleFonts) so the ₱ peso sign and other
/// non-Latin glyphs render correctly — Helvetica/built-in fonts lack them.
class ReceiptPrinterService {
  const ReceiptPrinterService();

  // ── Thermal printer persistence ────────────────────────────────────────

  static const _kPrinterUrl = 'receipt_thermal_printer_url';
  static const _kPrinterName = 'receipt_thermal_printer_name';
  static const _kCustomPrinters = 'receipt_custom_printers';

  /// Persist the user-chosen thermal printer URL + display name.
  static Future<void> savePrinter({
    required String url,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrinterUrl, url);
    await prefs.setString(_kPrinterName, name);
  }

  /// Returns the saved thermal printer URL, or empty string if none saved.
  static Future<String> loadPrinterUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPrinterUrl) ?? '';
  }

  /// Returns the saved thermal printer display name, or empty string if none.
  static Future<String> loadPrinterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPrinterName) ?? '';
  }

  /// Clears the saved thermal printer selection.
  static Future<void> clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrinterUrl);
    await prefs.remove(_kPrinterName);
  }

  // ── Custom / manually-added printers ──────────────────────────────────

  /// Returns all manually-added printers (name + ip pairs).
  static Future<List<CustomPrinterEntry>> loadCustomPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCustomPrinters) ?? '[]';
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(CustomPrinterEntry.fromJson).toList();
  }

  /// Adds a new custom printer. Duplicate IPs are replaced.
  static Future<void> addCustomPrinter(CustomPrinterEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadCustomPrinters();
    final updated = [
      ...existing.where((e) => e.ip != entry.ip),
      entry,
    ];
    await prefs.setString(
      _kCustomPrinters,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  /// Removes a custom printer by IP address.
  static Future<void> removeCustomPrinter(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadCustomPrinters();
    final updated = existing.where((e) => e.ip != ip).toList();
    await prefs.setString(
      _kCustomPrinters,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    // If the removed printer was the selected one, clear selection too.
    final selectedUrl = await loadPrinterUrl();
    if (selectedUrl == customPrinterUrl(ip)) await clearPrinter();
  }

  /// Builds the pseudo-URL used for a custom printer (used to match selection).
  static String customPrinterUrl(String ip) => 'custom://$ip';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Builds and returns the raw PDF bytes for this receipt.
  Future<Uint8List> buildPdf({
    required ReceiptSettings settings,
    required String transactionId,
    required String invoiceNumber,
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
  }) => _buildPdf(
        settings: settings,
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

  Future<void> printReceipt({
    required ReceiptSettings settings,
    required String transactionId,
    required String invoiceNumber,
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

    final name = 'receipt_${transactionId.substring(0, 8)}';

    if (share) {
      await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
      return;
    }

    // ── Direct thermal print (skip dialog) ──────────────────────────────
    if (settings.thermalPrinterEnabled) {
      final printerUrl = await loadPrinterUrl();
      if (printerUrl.isNotEmpty) {
        // Bluetooth ESC/POS path
        if (printerUrl.startsWith('bt://')) {
          final mac = printerUrl.replaceFirst('bt://', '');
          await _printViaBluetooth(mac: mac, pdfBytes: bytes, settings: settings);
          return;
        }
        // System printer path
        final printers = await Printing.listPrinters();
        final Printer? printer = printers
            .where((p) => p.url == printerUrl)
            .cast<Printer?>()
            .firstOrNull;
        if (printer != null) {
          await Printing.directPrintPdf(
            printer: printer,
            onLayout: (_) async => bytes,
            name: name,
          );
          if (settings.printDuplicateCopy) {
            await Printing.directPrintPdf(
              printer: printer,
              onLayout: (_) async => bytes,
              name: '${name}_copy',
            );
          }
          return;
        }
      }
    }

    // ── Fall back to OS print dialog ─────────────────────────────────────
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
    if (settings.printDuplicateCopy) {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${name}_copy',
      );
    }
  }

  // ── Bluetooth ESC/POS printing ────────────────────────────────────────────

  Future<void> _printViaBluetooth({
    required String mac,
    required Uint8List pdfBytes,
    required ReceiptSettings settings,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!connected) {
      throw Exception(
        '[ReceiptPrinterService] Could not connect to BT printer at $mac',
      );
    }
    // Standard printable dot-widths for 203-DPI thermal heads.
    // PDF rasters at ~464/638px wide; sending that raw shifts and blurs the
    // image because the print head is narrower — must scale to exact dot count.
    final targetWidth = settings.paperSize == '58mm' ? 384 : 576;

    try {
      // Use fewer feed lines before the cut on the first copy so the gap
      // between original and duplicate isn't too wide.
      final firstFeed = settings.printDuplicateCopy ? 2 : 6;
      await for (final raster in Printing.raster(pdfBytes, dpi: 203)) {
        final escPos = _rasterToEscPos(raster, targetWidth: targetWidth, feedLines: firstFeed);
        final ok = await PrintBluetoothThermal.writeBytes(escPos);
        if (!ok) debugPrint('[ReceiptPrinterService] BT write failed');
      }
      if (settings.printDuplicateCopy) {
        await for (final raster in Printing.raster(pdfBytes, dpi: 203)) {
          await PrintBluetoothThermal.writeBytes(
            _rasterToEscPos(raster, targetWidth: targetWidth),
          );
        }
      }
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

  // Converts a PDF raster page to ESC/POS GS v 0 raster-image bytes.
  // Scales to targetWidth dots so the image matches the print head exactly —
  // sending a wider image causes the printer to clip/compress, causing blur.
  List<int> _rasterToEscPos(PdfRaster raster, {required int targetWidth, int feedLines = 6}) {
    final result = <int>[];
    result.addAll([0x1B, 0x40]);       // ESC @ — initialise printer
    result.addAll([0x1B, 0x33, 0x00]); // ESC 3 0 — zero line spacing

    final srcW = raster.width;
    final srcH = raster.height;
    final dstW = targetWidth;
    final dstH = (srcH * dstW / srcW).round();
    final bytesPerRow = (dstW + 7) ~/ 8;

    // GS v 0 — raster bit image, normal density
    result.addAll([
      0x1D, 0x76, 0x30, 0x00,
      bytesPerRow & 0xFF, (bytesPerRow >> 8) & 0xFF,
      dstH & 0xFF, (dstH >> 8) & 0xFF,
    ]);

    final src = raster.pixels; // RGBA, 4 bytes per pixel

    for (var y = 0; y < dstH; y++) {
      for (var bx = 0; bx < bytesPerRow; bx++) {
        var byte = 0;
        for (var bit = 0; bit < 8; bit++) {
          final x = bx * 8 + bit;
          if (x < dstW) {
            final lum = _sampleLum(src, srcW, srcH, x, y, dstW, dstH);
            if (lum < 128) byte |= (0x80 >> bit);
          }
        }
        result.add(byte);
      }
    }

    result.addAll(List.filled(feedLines, 0x0A)); // feed N lines before cut
    result.addAll([0x1D, 0x56, 0x41, 0x05]);   // GS V A 5 — partial cut + feed
    return result;
  }

  // Bilinear-sampled luminance, alpha-composited onto white.
  // Bilinear interpolation avoids the jagged edges that nearest-neighbour
  // produces when downscaling ~464→384 or ~638→576 pixels.
  double _sampleLum(
    List<int> src, int srcW, int srcH,
    int dstX, int dstY, int dstW, int dstH,
  ) {
    final sx = dstX * (srcW - 1) / (dstW - 1);
    final sy = dstY * (srcH - 1) / (dstH - 1);
    final x0 = sx.floor().clamp(0, srcW - 1);
    final x1 = sx.ceil().clamp(0, srcW - 1);
    final y0 = sy.floor().clamp(0, srcH - 1);
    final y1 = sy.ceil().clamp(0, srcH - 1);
    final fx = sx - x0;
    final fy = sy - y0;

    double pixLum(int px, int py) {
      final i = (py * srcW + px) * 4;
      final a = src[i + 3] / 255.0;
      final r = src[i] * a + 255.0 * (1.0 - a);
      final g = src[i + 1] * a + 255.0 * (1.0 - a);
      final b = src[i + 2] * a + 255.0 * (1.0 - a);
      return 0.299 * r + 0.587 * g + 0.114 * b;
    }

    return pixLum(x0, y0) * (1 - fx) * (1 - fy)
         + pixLum(x1, y0) * fx * (1 - fy)
         + pixLum(x0, y1) * (1 - fx) * fy
         + pixLum(x1, y1) * fx * fy;
  }

  // ── PDF builder ───────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf({
    required ReceiptSettings settings,
    required String transactionId,
    required String invoiceNumber,
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
        ? PdfPageFormat(
            58 * PdfPageFormat.mm,
            double.infinity,
            marginLeft: 1.5 * PdfPageFormat.mm,
            marginRight: 1.5 * PdfPageFormat.mm,
            marginTop: 3 * PdfPageFormat.mm,
            marginBottom: 3 * PdfPageFormat.mm,
          )
        : PdfPageFormat(
            80 * PdfPageFormat.mm,
            double.infinity,
            marginLeft: 1.5 * PdfPageFormat.mm,
            marginRight: 1.5 * PdfPageFormat.mm,
            marginTop: 4 * PdfPageFormat.mm,
            marginBottom: 4 * PdfPageFormat.mm,
          );

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

    const currency = '₱';

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
              _text(
                settings.headerText,
                baseFs - 0.5,
                fonts,
                align: align,
              ),
              pw.SizedBox(height: 3),
            ],

            // ── Business info ────────────────────────────────────────
            if (settings.businessName.isNotEmpty)
              _text(
                settings.businessName,
                baseFs + 2,
                fonts,
                bold: true,
                align: align,
              ),
            if (settings.storeName.isNotEmpty)
              _text(settings.storeName, baseFs, fonts, align: align),
            if (settings.address.isNotEmpty)
              _text(
                settings.address,
                baseFs - 0.5,
                fonts,
                align: align,
              ),
            if (settings.contactNumber.isNotEmpty)
              _text(
                'Tel: ${settings.contactNumber}',
                baseFs - 0.5,
                fonts,
                align: align,
              ),
            if (settings.email.isNotEmpty)
              _text(
                settings.email,
                baseFs - 0.5,
                fonts,
                align: align,
              ),
            if (settings.website.isNotEmpty)
              _text(
                settings.website,
                baseFs - 0.5,
                fonts,
                align: align,
              ),
            if (settings.tinNumber.isNotEmpty)
              _text(
                'TIN: ${settings.tinNumber}',
                baseFs - 0.5,
                fonts,
                align: align,
              ),

            _divider(fonts, baseFs),

            // ── Transaction meta ─────────────────────────────────────
            if (settings.showOrderId)
              _metaRow('Invoice #:', invoiceNumber, baseFs, fonts),
            if (settings.showDateTime)
              _metaRow('Date:', _fmtDate(dateTime), baseFs, fonts),
            if (settings.showCashierName && cashierName.isNotEmpty)
              _metaRow('Cashier:', cashierName, baseFs, fonts),
            _metaRow(
              'Customer:',
              customerName.isNotEmpty ? customerName : 'Walk-in Customer',
              baseFs,
              fonts,
            ),
            _metaRow('Payment:', _fmtPayment(paymentMethod), baseFs, fonts),

            _divider(fonts, baseFs),

            // ── Items ────────────────────────────────────────────────
            ...items.map((i) => _itemRow(i, baseFs, currency, fonts)),

            _solidDivider(),

            // ── Totals ───────────────────────────────────────────────
            _totalRow('Subtotal', _fmt(subtotal, currency), baseFs, fonts),
            if (discountAmount > 0)
              _totalRow(
                'Discount',
                '- ${_fmt(discountAmount, currency)}',
                baseFs,
                fonts,
              ),
            if (settings.showTaxBreakdown && taxAmount > 0)
              _totalRow(
                'VAT (incl.)',
                _fmt(taxAmount, currency),
                baseFs,
                fonts,
              ),
            _totalRow(
              'TOTAL',
              _fmt(total, currency),
              baseFs + 1.5,
              fonts,
              bold: true,
            ),
            if (amountReceived > 0 && paymentMethod == 'cash') ...[
              _totalRow(
                'Cash Received',
                _fmt(amountReceived, currency),
                baseFs,
                fonts,
              ),
              _totalRow(
                'Change',
                _fmt(change, currency),
                baseFs,
                fonts,
                bold: true,
              ),
            ],

            if (taxAmount > 0) ...[
              pw.SizedBox(height: 3),
              _text(
                '(VAT inclusive)',
                baseFs - 1.5,
                fonts,
                align: pw.TextAlign.center,
              ),
            ],

            _divider(fonts, baseFs),

            // ── Footer ───────────────────────────────────────────────
            if (settings.footerText.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              _text(
                settings.footerText,
                baseFs,
                fonts,
                bold: true,
                align: pw.TextAlign.center,
              ),
            ],
            if (settings.returnPolicy.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              _text(
                settings.returnPolicy,
                baseFs - 1,
                fonts,
                align: pw.TextAlign.center,
              ),
            ],
            if (settings.customNotes.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              _text(
                settings.customNotes,
                baseFs - 1,
                fonts,
                align: pw.TextAlign.center,
              ),
            ],
            if (settings.showQrCode) ...[
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: transactionId,
                  width: 60,
                  height: 60,
                ),
              ),
              pw.SizedBox(height: 6),
            ],
            pw.SizedBox(height: 4),
            _text(
              '* * *',
              baseFs - 1,
              fonts,
              align: pw.TextAlign.center,
            ),
            // Extra space so the user can tear the receipt cleanly
            pw.SizedBox(height: 24),
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
        if (await file.exists()) {
          return pw.MemoryImage(await file.readAsBytes());
        }
      }
      if (s.logoUrl.isNotEmpty) return await networkImage(s.logoUrl);
    } catch (e, st) {
      debugPrint('[ReceiptPrinterService] Error loading logo: $e\n$st');
    }
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
  }) => pw.Text(
    text,
    textAlign: align,
    style: pw.TextStyle(
      font: bold ? fonts.bold : fonts.regular,
      fontSize: fontSize,
      color: color,
    ),
  );

  // Uses pw.Divider to avoid the overflow that '- ' * N causes when the
  // repeated string exceeds the printable width and wraps onto extra lines.
  pw.Widget _divider(_Fonts fonts, double baseFs) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Divider(color: PdfColors.grey700, thickness: 0.5),
  );

  pw.Widget _solidDivider() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Divider(color: PdfColors.black, thickness: 0.8),
  );

  pw.Widget _metaRow(String label, String value, double fs, _Fonts fonts) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5),
        child: pw.Row(
          children: [
            _text(label, fs - 1, fonts),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(font: fonts.bold, fontSize: fs - 1),
              ),
            ),
          ],
        ),
      );

  pw.Widget _itemRow(CartItem item, double fs, String currency, _Fonts fonts) {
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
          _text(
            '  $qty x ${_fmt(item.unitPrice, currency)}',
            fs - 1.5,
            fonts,
            color: PdfColors.grey500,
          ),
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
  }) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      children: [
        pw.Expanded(child: _text(label, fs, fonts, bold: bold, color: color)),
        _text(value, fs, fonts, bold: bold, color: color),
      ],
    ),
  );

  // ── Formatters ────────────────────────────────────────────────────────────

  String _fmt(double v, String currency) {
    if (v >= 1_000_000) {
      return '$currency${(v / 1_000_000).toStringAsFixed(2)}M';
    }
    return '$currency${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
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

// ── Custom printer entry ──────────────────────────────────────────────────────

class CustomPrinterEntry {
  final String name;
  final String ip;

  const CustomPrinterEntry({required this.name, required this.ip});

  factory CustomPrinterEntry.fromJson(Map<String, dynamic> json) =>
      CustomPrinterEntry(
        name: json['name'] as String,
        ip: json['ip'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'ip': ip};
}
