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
import 'package:printing/printing.dart';

/// Assembles all sections into a premium A4 PDF document.
///
/// Structure:
///   Page 1   — Cover + Executive Summary  (pw.Page, no footer)
///   Page 2+  — Section content           (pw.MultiPage, paginated)
class ReportPdfBuilder {
  static Future<Uint8List> build({
    required ReportsData data,
    required ReportPeriod period,
    required String businessName,
    required String branchLabel,
  }) async {
    // Noto Sans has full Unicode coverage — renders ₱ and all other symbols.
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontItalic = await PdfGoogleFonts.notoSansItalic();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    final pdf = pw.Document(
      title: 'Business Analytics Report',
      author: businessName.isNotEmpty ? businessName : 'POS System',
    );

    // ── Page 1: Cover (no footer, full-bleed layout) ─────────────────────────
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 0, 48, 48),
        build: (_) => buildCoverPage(
          businessName: businessName,
          branchLabel: branchLabel,
          period: period,
          data: data,
        ),
      ),
    );

    // ── Pages 2+: Content sections (paginated, with footer) ──────────────────
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        footer: (ctx) => PdfS.footer(ctx, businessName),
        build: (_) => [
          ...buildSalesSection(data),
          pw.NewPage(),
          ...buildInventorySection(data),
          pw.NewPage(),
          ...buildProfitSection(data),
          if (data.branchStats.isNotEmpty) ...[
            pw.NewPage(),
            ...buildBranchSection(data),
          ],
        ],
      ),
    );

    return pdf.save();
  }
}
