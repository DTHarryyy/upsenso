import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_builder.dart';
import 'package:pos/features/reports/pdf/_pdf_saver_stub.dart'
    if (dart.library.io) 'package:pos/features/reports/pdf/_pdf_saver_io.dart'
    if (dart.library.html) 'package:pos/features/reports/pdf/_pdf_saver_web.dart';

class ReportPdfExporter {
  /// Returns true when the user completed the save/share, false if they
  /// dismissed the share sheet.
  static Future<bool> export({
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
    return sharePdfBytes(bytes, filename);
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
