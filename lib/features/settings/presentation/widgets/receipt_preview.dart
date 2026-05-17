import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';

/// Live receipt preview that mirrors exactly what will be printed.
/// Re-renders on every [ReceiptSettings] change — no state needed.
class ReceiptPreview extends StatelessWidget {
  final ReceiptSettings settings;
  const ReceiptPreview({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final paperWidth = settings.paperSize == '58mm' ? 200.0 : 280.0;
    final baseFontSize = switch (settings.fontSize) {
      'small' => 10.0,
      'large' => 13.0,
      _ => 11.5,
    };
    final align = switch (settings.textAlignment) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };

    return Center(
      child: Container(
        width: paperWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: _ReceiptBody(
          settings: settings,
          baseFontSize: baseFontSize,
          align: align,
        ),
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  final ReceiptSettings settings;
  final double baseFontSize;
  final TextAlign align;

  const _ReceiptBody({
    required this.settings,
    required this.baseFontSize,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final currency = s.currencySymbol;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Logo ──────────────────────────────────────────────────────
        if (s.showLogo && _hasLogo(s)) ...[
          Center(child: _LogoWidget(settings: s)),
          const SizedBox(height: 8),
        ],

        // ── Header text ───────────────────────────────────────────────
        if (s.headerText.isNotEmpty) ...[
          _line(s.headerText, baseFontSize - 0.5, align,
              color: Colors.black54),
          const SizedBox(height: 4),
        ],

        // ── Business name ─────────────────────────────────────────────
        if (s.businessName.isNotEmpty)
          _line(s.businessName, baseFontSize + 2, align,
              bold: true),
        if (s.storeName.isNotEmpty)
          _line(s.storeName, baseFontSize, align),
        if (s.address.isNotEmpty)
          _line(s.address, baseFontSize - 0.5, align,
              color: Colors.black54),
        if (s.contactNumber.isNotEmpty)
          _line('Tel: ${s.contactNumber}', baseFontSize - 0.5, align,
              color: Colors.black54),
        if (s.email.isNotEmpty)
          _line(s.email, baseFontSize - 0.5, align, color: Colors.black54),
        if (s.website.isNotEmpty)
          _line(s.website, baseFontSize - 0.5, align, color: Colors.black54),
        if (s.tinNumber.isNotEmpty)
          _line('TIN: ${s.tinNumber}', baseFontSize - 0.5, align,
              color: Colors.black54),

        _dottedDivider(),

        // ── Order meta ────────────────────────────────────────────────
        if (s.showOrderId)
          _metaRow('Invoice #:', 'INV-00001', baseFontSize),
        if (s.showDateTime)
          _metaRow(
              'Date:', _fmtDate(DateTime.now()), baseFontSize),
        if (s.showCashierName)
          _metaRow('Cashier:', 'Sample Cashier', baseFontSize),
        if (s.showCustomerName)
          _metaRow('Customer:', 'Walk-in Customer', baseFontSize),
        _metaRow('Payment:', 'Cash', baseFontSize),

        _dottedDivider(),

        // ── Sample items ──────────────────────────────────────────────
        _itemRow('Product A x2', '${currency}120.00', baseFontSize),
        _itemRow('Product B x1', '${currency}85.00', baseFontSize),
        _itemRow('Product C x3', '${currency}210.00', baseFontSize),

        _solidDivider(),

        // ── Totals ────────────────────────────────────────────────────
        _totalRow('Subtotal', '${currency}415.00', baseFontSize),
        if (s.showTaxBreakdown && s.taxPercentage > 0) ...[
          _totalRow(
            'VAT (${s.taxPercentage.toStringAsFixed(0)}%)',
            '$currency${(415 * s.taxPercentage / 100).toStringAsFixed(2)}',
            baseFontSize,
            color: Colors.black54,
          ),
        ],
        if (s.serviceChargePercentage > 0)
          _totalRow(
            'Service (${s.serviceChargePercentage.toStringAsFixed(0)}%)',
            '$currency${(415 * s.serviceChargePercentage / 100).toStringAsFixed(2)}',
            baseFontSize,
            color: Colors.black54,
          ),
        _totalRow(
          'TOTAL',
          '${currency}415.00',
          baseFontSize + 1,
          bold: true,
        ),
        _totalRow('Cash Tendered', '${currency}500.00', baseFontSize),
        _totalRow(
          'Change',
          '${currency}85.00',
          baseFontSize,
          color: AppColors.success,
        ),

        if (s.vatInclusive) ...[
          const SizedBox(height: 4),
          _line('(VAT inclusive)', baseFontSize - 1, align,
              color: Colors.black38),
        ],

        _dottedDivider(),

        // ── QR code placeholder ───────────────────────────────────────
        if (s.showQrCode) ...[
          Center(
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(IconlyLight.scan,
                  size: 48, color: Colors.black54),
            ),
          ),
        ],

        // ── Footer ────────────────────────────────────────────────────
        if (s.footerText.isNotEmpty) ...[
          const SizedBox(height: 4),
          _line(s.footerText, baseFontSize, align, bold: true),
        ],
        if (s.returnPolicy.isNotEmpty) ...[
          const SizedBox(height: 4),
          _line(s.returnPolicy, baseFontSize - 1, align,
              color: Colors.black45),
        ],
        if (s.customNotes.isNotEmpty) ...[
          const SizedBox(height: 4),
          _line(s.customNotes, baseFontSize - 1, align,
              color: Colors.black45),
        ],
        const SizedBox(height: 4),
        _line('* * *', baseFontSize, TextAlign.center, color: Colors.black26),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _hasLogo(ReceiptSettings s) =>
      s.logoLocalPath.isNotEmpty || s.logoUrl.isNotEmpty;

  Widget _line(String text, double size, TextAlign align,
      {bool bold = false, Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
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
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: getOutfitStyle(
                  fontSize: size - 0.5, color: Colors.black54)),
          Text(value,
              style: getOutfitStyle(
                  fontSize: size - 0.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _itemRow(String name, String amount, double size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style: getOutfitStyle(fontSize: size, color: Colors.black87)),
          ),
          Text(amount,
              style: getOutfitStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String amount, double size,
      {bool bold = false, Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: getOutfitStyle(
                  fontSize: size,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color)),
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          '- ' * 30,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: getOutfitStyle(fontSize: 8, color: Colors.black26),
        ),
      );

  Widget _solidDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(height: 1, color: Colors.black26),
      );

  String _fmtDate(DateTime dt) =>
      '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
        height: 60,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => _urlFallback(),
      );
    }
    if (settings.logoUrl.isNotEmpty) {
      return _urlFallback();
    }
    return const SizedBox.shrink();
  }

  Widget _urlFallback() {
    if (settings.logoUrl.isEmpty) return const SizedBox.shrink();
    return Image.network(
      settings.logoUrl,
      height: 60,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => const Icon(IconlyLight.image,
          size: 40, color: Colors.black26),
    );
  }
}
