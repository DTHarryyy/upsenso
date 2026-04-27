import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';

/// Returns an empty list when there are no branch stats — caller skips it.
List<pw.Widget> buildBranchSection(ReportsData data) {
  if (data.branchStats.isEmpty) return [];

  return [
    PdfS.sectionHeader('Branch Comparison'),
    pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1.8),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.8),
        4: const pw.FlexColumnWidth(1.8),
      },
      children: [
        PdfS.tableHeaderRow(
            ['Branch', 'Total Sales', 'Txns', 'Avg. Ticket', 'vs Last Period']),
        ...List.generate(data.branchStats.length, (i) {
          final b = data.branchStats[i];
          final vsSign = b.vsLastPeriodPct >= 0 ? '+' : '';
          return PdfS.tableDataRow(
            [
              b.isTop ? '${b.name} ★' : b.name,
              pdfCurrency(b.totalSales),
              b.transactions.toString(),
              pdfCurrency(b.avgTicket),
              '$vsSign${b.vsLastPeriodPct.toStringAsFixed(1)}%',
            ],
            i,
          );
        }),
      ],
    ),
  ];
}
