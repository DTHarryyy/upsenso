import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ── PDF-safe formatters ───────────────────────────────────────────────────────
// Built-in PDF fonts (Helvetica) don't include ₱ (U+20B1), so we use "PHP".

String pdfCurrency(double v) {
  if (v >= 1000000) return 'PHP ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'PHP ${(v / 1000).toStringAsFixed(1)}k';
  return 'PHP ${v.toStringAsFixed(0)}';
}

// ─────────────────────────────────────────────────────────────────────────────

/// Shared PDF colors, text styles, and widget builders for report PDFs.
class PdfS {
  PdfS._();

  // ── Colors ───────────────────────────────────────────────────────────────────

  static final brand = PdfColor.fromHex('557FF4');
  static final brandSoft = PdfColor.fromHex('EAF0FF');
  static final textPrimary = PdfColor.fromHex('0F172A');
  static final textSecondary = PdfColor.fromHex('475569');
  static final textMuted = PdfColor.fromHex('94A3B8');
  static final borderSoft = PdfColor.fromHex('E2E8F0');
  static final rowAlt = PdfColor.fromHex('F7F9FC');
  static final successColor = PdfColor.fromHex('22C55E');
  static final errorColor = PdfColor.fromHex('DC2626');
  static final warningColor = PdfColor.fromHex('F59E0B');

  // ── Text styles ──────────────────────────────────────────────────────────────

  static pw.TextStyle h1() => pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
        color: brand,
      );

  static pw.TextStyle h2() => pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: brand,
      );

  static pw.TextStyle h3() => pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: textPrimary,
      );

  static pw.TextStyle body() => pw.TextStyle(fontSize: 8.5, color: textPrimary);

  static pw.TextStyle bodySmall() =>
      pw.TextStyle(fontSize: 7.5, color: textSecondary);

  static pw.TextStyle tblHeader() => pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      );

  static pw.TextStyle statValue() => pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: textPrimary,
      );

  static pw.TextStyle statLabel() =>
      pw.TextStyle(fontSize: 7.5, color: textSecondary);

  // ── Section / sub headers ────────────────────────────────────────────────────

  static pw.Widget sectionHeader(String title) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 20, bottom: 10),
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: pw.BoxDecoration(
          color: brandSoft,
          // borderRadius omitted: pdf package forbids radius with a non-uniform border
          border: pw.Border(left: pw.BorderSide(color: brand, width: 3)),
        ),
        child: pw.Text(title, style: h2()),
      );

  static pw.Widget subHeader(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
        child: pw.Text(title, style: h3()),
      );

  static pw.Widget divider() => pw.Container(
        height: 0.5,
        margin: const pw.EdgeInsets.symmetric(vertical: 8),
        color: borderSoft,
      );

  // ── Tables ───────────────────────────────────────────────────────────────────

  static pw.TableRow tableHeaderRow(List<String> labels) => pw.TableRow(
        decoration: pw.BoxDecoration(color: brand),
        children: labels
            .map((l) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  child: pw.Text(l, style: tblHeader()),
                ))
            .toList(),
      );

  static pw.TableRow tableDataRow(
    List<String> cells,
    int rowIndex, {
    List<pw.TextStyle?>? cellStyles,
  }) =>
      pw.TableRow(
        decoration: pw.BoxDecoration(
            color: rowIndex.isOdd ? rowAlt : PdfColors.white),
        children: List.generate(
          cells.length,
          (i) => pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: pw.Text(cells[i], style: cellStyles?[i] ?? body()),
          ),
        ),
      );

  // ── Stat boxes ───────────────────────────────────────────────────────────────

  static pw.Widget statBox({
    required String label,
    required String value,
    String? change,
    bool? isPositive,
  }) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: borderSoft),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: statLabel()),
            pw.SizedBox(height: 4),
            pw.Text(value, style: statValue()),
            if (change != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                change,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: isPositive == true
                      ? successColor
                      : (isPositive == false ? errorColor : textMuted),
                ),
              ),
            ],
          ],
        ),
      );

  // ── Footer ───────────────────────────────────────────────────────────────────

  static pw.Widget footer(pw.Context context, String businessName) =>
      pw.Column(
        children: [
          pw.Container(height: 0.5, color: borderSoft),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                businessName.isNotEmpty
                    ? '$businessName — Reports & Analytics'
                    : 'Reports & Analytics',
                style: pw.TextStyle(fontSize: 7, color: textMuted),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: textMuted),
              ),
            ],
          ),
        ],
      );
}
