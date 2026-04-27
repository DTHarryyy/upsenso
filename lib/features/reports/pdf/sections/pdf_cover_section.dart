import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';

List<pw.Widget> buildCoverSection({
  required String businessName,
  required String branchLabel,
  required ReportPeriod period,
}) {
  return [
    pw.SizedBox(height: 8),

    // ── Title block ──────────────────────────────────────────────────────────
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 5,
          height: 46,
          color: PdfS.brand,
          margin: const pw.EdgeInsets.only(right: 14),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (businessName.isNotEmpty) ...[
              pw.Text(
                businessName,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfS.textSecondary,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
            ],
            pw.Text('Reports & Analytics', style: PdfS.h1()),
          ],
        ),
      ],
    ),

    pw.SizedBox(height: 18),
    PdfS.divider(),
    pw.SizedBox(height: 12),

    // ── Metadata row ─────────────────────────────────────────────────────────
    pw.Row(
      children: [
        _chip(label: 'PERIOD', value: period.label),
        pw.SizedBox(width: 32),
        _chip(label: 'BRANCH', value: branchLabel),
        pw.SizedBox(width: 32),
        _chip(label: 'GENERATED', value: _formatNow()),
      ],
    ),

    pw.SizedBox(height: 18),
    PdfS.divider(),
  ];
}

pw.Widget _chip({required String label, required String value}) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            color: PdfS.textMuted,
            letterSpacing: 0.8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfS.textPrimary,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );

String _formatNow() {
  final dt = DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = dt.hour > 12
      ? dt.hour - 12
      : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m $ampm';
}
