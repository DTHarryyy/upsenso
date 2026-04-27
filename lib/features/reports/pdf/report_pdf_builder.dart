import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';
import 'package:pos/features/reports/pdf/sections/pdf_branch_section.dart';
import 'package:pos/features/reports/pdf/sections/pdf_cover_section.dart';
import 'package:pos/features/reports/pdf/sections/pdf_inventory_section.dart';
import 'package:pos/features/reports/pdf/sections/pdf_profit_section.dart';
import 'package:pos/features/reports/pdf/sections/pdf_sales_section.dart';

/// Assembles all report sections into a single A4 PDF document.
class ReportPdfBuilder {
  static Future<Uint8List> build({
    required ReportsData data,
    required ReportPeriod period,
    required String businessName,
    required String branchLabel,
  }) async {
    final pdf = pw.Document(
      title: 'Reports & Analytics',
      author: businessName.isNotEmpty ? businessName : 'POS System',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        footer: (ctx) => PdfS.footer(ctx, businessName),
        build: (ctx) => [
          ...buildCoverSection(
            businessName: businessName,
            branchLabel: branchLabel,
            period: period,
          ),
          ...buildSalesSection(data),
          ...buildInventorySection(data),
          ...buildProfitSection(data),
          ...buildBranchSection(data),
        ],
      ),
    );

    return pdf.save();
  }
}
