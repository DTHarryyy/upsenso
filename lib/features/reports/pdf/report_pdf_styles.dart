import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ── Currency formatter ────────────────────────────────────────────────────────

String pdfCurrency(double v) {
  if (v >= 1_000_000) return '₱${(v / 1_000_000).toStringAsFixed(2)}M';
  if (v >= 1_000) return '₱${(v / 1_000).toStringAsFixed(1)}k';
  return '₱${v.toStringAsFixed(0)}';
}

String pdfCurrencyFull(double v) {
  final abs = v.abs().toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < abs.length; i++) {
    if (i > 0 && (abs.length - i) % 3 == 0) buf.write(',');
    buf.write(abs[i]);
  }
  final formatted = buf.toString();
  return v < 0 ? '₱-$formatted' : '₱$formatted';
}

// ── Metric data model ─────────────────────────────────────────────────────────

class PdfMetric {
  final String label;
  final String value;
  final String? change;
  final bool? isPositive;
  const PdfMetric(this.label, this.value, {this.change, this.isPositive});
}

// ─────────────────────────────────────────────────────────────────────────────

class PdfS {
  PdfS._();

  // ── Colors ───────────────────────────────────────────────────────────────────

  static final ink = PdfColor.fromHex('1E293B');          // slate-800 – primary text
  static final inkSub = PdfColor.fromHex('475569');       // slate-600
  static final inkMuted = PdfColor.fromHex('94A3B8');     // slate-400
  static final accent = PdfColor.fromHex('2563EB');       // blue-600
  static final accentSoft = PdfColor.fromHex('EFF6FF');   // blue-50
  static final success = PdfColor.fromHex('059669');
  static final error = PdfColor.fromHex('DC2626');
  static final warning = PdfColor.fromHex('D97706');
  static final divider = PdfColor.fromHex('E2E8F0');      // slate-200
  static final dividerStrong = PdfColor.fromHex('64748B');// slate-500
  static final rowAlt = PdfColor.fromHex('F8FAFC');       // slate-50
  static final rowTotal = PdfColor.fromHex('F1F5F9');     // slate-100

  // ── Text styles ──────────────────────────────────────────────────────────────

  static pw.TextStyle display() => pw.TextStyle(
        fontSize: 28, fontWeight: pw.FontWeight.bold, color: ink);

  static pw.TextStyle headlineS() => pw.TextStyle(
        fontSize: 13, fontWeight: pw.FontWeight.bold, color: inkSub,
        letterSpacing: 0.3);

  static pw.TextStyle sectionNum() => pw.TextStyle(
        fontSize: 8, fontWeight: pw.FontWeight.bold,
        color: accent, letterSpacing: 1.5);

  static pw.TextStyle sectionTitle() => pw.TextStyle(
        fontSize: 17, fontWeight: pw.FontWeight.bold, color: ink);

  static pw.TextStyle subsection() => pw.TextStyle(
        fontSize: 8.5, fontWeight: pw.FontWeight.bold,
        color: inkSub, letterSpacing: 0.8);

  static pw.TextStyle metaLbl() => pw.TextStyle(
        fontSize: 7, fontWeight: pw.FontWeight.bold,
        color: inkMuted, letterSpacing: 1);

  static pw.TextStyle metaVal() => pw.TextStyle(
        fontSize: 10, fontWeight: pw.FontWeight.bold, color: ink);

  static pw.TextStyle kpiValue() => pw.TextStyle(
        fontSize: 22, fontWeight: pw.FontWeight.bold, color: ink);

  static pw.TextStyle kpiLabel() => pw.TextStyle(
        fontSize: 7, fontWeight: pw.FontWeight.bold,
        color: inkMuted, letterSpacing: 1);

  static pw.TextStyle kpiChange({bool? positive}) => pw.TextStyle(
        fontSize: 8, fontWeight: pw.FontWeight.bold,
        color: positive == true ? success : (positive == false ? error : inkMuted));

  static pw.TextStyle tableHdr() => pw.TextStyle(
        fontSize: 7.5, fontWeight: pw.FontWeight.bold,
        color: inkSub, letterSpacing: 0.5);

  static pw.TextStyle tableCell() => pw.TextStyle(fontSize: 8.5, color: ink);

  static pw.TextStyle tableCellMuted() =>
      pw.TextStyle(fontSize: 8.5, color: inkSub);

  static pw.TextStyle tableTotal() => pw.TextStyle(
        fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: ink);

  static pw.TextStyle body() => pw.TextStyle(fontSize: 9, color: ink);

  static pw.TextStyle bodySmall() => pw.TextStyle(fontSize: 8, color: inkSub);

  static pw.TextStyle caption() => pw.TextStyle(fontSize: 7.5, color: inkMuted);

  // ── Structural primitives ─────────────────────────────────────────────────────

  static pw.Widget sp([double h = 16]) => pw.SizedBox(height: h);

  static pw.Widget heavyRule() => pw.Container(height: 1.5, color: ink);

  static pw.Widget rule([PdfColor? c]) =>
      pw.Container(height: 0.5, color: c ?? divider);

  // ── Section header (numbered, annual-report style) ────────────────────────────

  static pw.Widget sectionHeader(String number, String title,
          {String? description}) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          sp(24),
          heavyRule(),
          sp(10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(number, style: sectionNum()),
              pw.SizedBox(width: 14),
              pw.Text(title, style: sectionTitle()),
            ],
          ),
          sp(10),
          heavyRule(),
          if (description != null) ...[
            sp(8),
            pw.Text(description, style: bodySmall()),
          ],
          sp(18),
        ],
      );

  // ── Sub-section label ─────────────────────────────────────────────────────────

  static pw.Widget subHead(String title) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          sp(14),
          pw.Text(title.toUpperCase(), style: subsection()),
          sp(4),
          rule(),
          sp(4),
        ],
      );

  // ── KPI metric row (for cover + section summaries) ────────────────────────────
  // Metrics are laid out with a thin vertical rule between each.

  static pw.Widget metricRow(List<PdfMetric> metrics) {
    if (metrics.isEmpty) return pw.SizedBox();
    final blocks = <pw.Widget>[];
    for (int i = 0; i < metrics.length; i++) {
      blocks.add(pw.Expanded(child: _kpi(metrics[i])));
      if (i < metrics.length - 1) {
        blocks.add(pw.Container(
          width: 0.5,
          height: 54,
          color: divider,
          margin: const pw.EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        ));
      }
    }
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: blocks,
    );
  }

  static pw.Widget _kpi(PdfMetric m) => pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(0, 0, 12, 0),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(m.label.toUpperCase(), style: kpiLabel()),
            sp(3),
            pw.Text(m.value, style: kpiValue()),
            if (m.change != null) ...[
              sp(3),
              pw.Text(m.change!,
                  style: kpiChange(positive: m.isPositive)),
            ],
          ],
        ),
      );

  // ── Financial table (borderless rows, header + divider style) ────────────────

  static pw.Widget financialTable({
    required Map<int, pw.TableColumnWidth> columnWidths,
    required List<String> headers,
    required List<List<String>> rows,
    List<String>? totalsRow,
    List<int> rightAlignCols = const [],
    List<int> mutedCols = const [],
  }) =>
      pw.Table(
        columnWidths: columnWidths,
        children: [
          // ── Header
          pw.TableRow(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: dividerStrong, width: 0.8),
              ),
            ),
            children: List.generate(
              headers.length,
              (c) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    vertical: 6, horizontal: 4),
                child: pw.Text(
                  headers[c].toUpperCase(),
                  style: tableHdr(),
                  textAlign: rightAlignCols.contains(c)
                      ? pw.TextAlign.right
                      : pw.TextAlign.left,
                ),
              ),
            ),
          ),
          // ── Data rows
          ...List.generate(rows.length, (r) {
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: r.isOdd ? rowAlt : PdfColors.white,
                border: pw.Border(
                  bottom: pw.BorderSide(color: divider, width: 0.4),
                ),
              ),
              children: List.generate(
                rows[r].length,
                (c) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 5, horizontal: 4),
                  child: pw.Text(
                    rows[r][c],
                    style: mutedCols.contains(c)
                        ? tableCellMuted()
                        : tableCell(),
                    textAlign: rightAlignCols.contains(c)
                        ? pw.TextAlign.right
                        : pw.TextAlign.left,
                  ),
                ),
              ),
            );
          }),
          // ── Totals row
          if (totalsRow != null)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: rowTotal,
                border: pw.Border(
                  top: pw.BorderSide(color: dividerStrong, width: 0.8),
                ),
              ),
              children: List.generate(
                totalsRow.length,
                (c) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 6, horizontal: 4),
                  child: pw.Text(
                    totalsRow[c],
                    style: tableTotal(),
                    textAlign: rightAlignCols.contains(c)
                        ? pw.TextAlign.right
                        : pw.TextAlign.left,
                  ),
                ),
              ),
            ),
        ],
      );

  // ── Meta block (cover page detail pair) ──────────────────────────────────────

  static pw.Widget metaBlock(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: metaLbl()),
          sp(3),
          pw.Text(value, style: metaVal()),
        ],
      );

  // ── Inventory status badge (text only, colour-coded) ─────────────────────────

  static pw.Widget statusBadge(String label, PdfColor color) => pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      );

  // ── Footer ────────────────────────────────────────────────────────────────────

  static pw.Widget footer(pw.Context ctx, String businessName) => pw.Column(
        children: [
          rule(),
          sp(5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                businessName.isNotEmpty
                    ? '$businessName  —  Business Analytics Report'
                    : 'Business Analytics Report',
                style: caption(),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: caption(),
              ),
            ],
          ),
        ],
      );

  // ── Confidentiality line ──────────────────────────────────────────────────────

  static pw.Widget confidentialFooter() => pw.Text(
        'CONFIDENTIAL — For internal use only. Generated automatically by the POS system.',
        style: caption(),
      );
}
