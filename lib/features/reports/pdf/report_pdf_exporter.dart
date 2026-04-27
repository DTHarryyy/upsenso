import 'package:printing/printing.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_builder.dart';

/// Builds the PDF and hands it to the OS via [Printing.sharePdf].
///
/// On Android this opens the system share sheet — the user can pick
/// "Save to Downloads", Google Drive, email, etc.
/// On iOS it opens the share sheet where they can "Save to Files".
///
/// Returns the filename that was used so the caller can show it.
class ReportPdfExporter {
  static Future<String> export({
    required ReportsData data,
    required ReportPeriod period,
    required String businessName,
    required String branchLabel,
  }) async {
    final bytes = await ReportPdfBuilder.build(
      data: data,
      period: period,
      businessName: businessName,
      branchLabel: branchLabel,
    );

    final filename = _buildFilename(period);
    await Printing.sharePdf(bytes: bytes, filename: filename);
    return filename;
  }

  static String _buildFilename(ReportPeriod period) {
    final slug = period.label.toLowerCase().replaceAll(' ', '-');
    final now = DateTime.now();
    final stamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}-${_pad(now.hour)}${_pad(now.minute)}';
    return 'report-$slug-$stamp.pdf';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
