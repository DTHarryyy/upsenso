import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';

List<pw.Widget> buildBranchSection(ReportsData data) {
  if (data.branchStats.isEmpty) return [];

  double totalSales = 0;
  int totalTxns = 0;
  for (final b in data.branchStats) {
    totalSales += b.totalSales;
    totalTxns += b.transactions;
  }
  final avgTicket = totalTxns > 0 ? totalSales / totalTxns : 0.0;

  return [
    PdfS.sectionHeader(
      '04',
      'Branch Performance',
      description:
          'Sales breakdown and period-over-period comparison across all locations.',
    ),

    // ── Branch KPIs ─────────────────────────────────────────────────────────
    PdfS.metricRow([
      PdfMetric(
        'Active Branches',
        '${data.branchStats.length}',
      ),
      PdfMetric('Combined Sales', pdfCurrency(totalSales)),
      PdfMetric('Total Transactions', '$totalTxns'),
      PdfMetric('Overall Avg. Ticket', pdfCurrency(avgTicket)),
    ]),

    // ── Branch comparison table ──────────────────────────────────────────────
    PdfS.subHead('Branch Breakdown'),
    _branchTable(data, totalSales, totalTxns),
  ];
}

pw.Widget _branchTable(ReportsData data, double totalSales, int totalTxns) {
  return PdfS.financialTable(
    columnWidths: {
      0: const pw.FlexColumnWidth(2.8),
      1: const pw.FlexColumnWidth(1.8),
      2: const pw.FlexColumnWidth(1.3),
      3: const pw.FlexColumnWidth(1.8),
      4: const pw.FlexColumnWidth(1.2),
      5: const pw.FlexColumnWidth(1.5),
    },
    headers: [
      'Branch',
      'Total Sales',
      'Txns',
      'Avg. Ticket',
      'Share',
      'vs Last Period',
    ],
    rows: data.branchStats.map((b) {
      final share = totalSales > 0
          ? '${(b.totalSales / totalSales * 100).toStringAsFixed(1)}%'
          : '—';
      final vs = b.vsLastPeriodPct >= 0
          ? '+${b.vsLastPeriodPct.toStringAsFixed(1)}%'
          : '${b.vsLastPeriodPct.toStringAsFixed(1)}%';
      return [
        b.isTop ? '${b.name} (Top)' : b.name,
        pdfCurrency(b.totalSales),
        '${b.transactions}',
        pdfCurrency(b.avgTicket),
        share,
        vs,
      ];
    }).toList(),
    totalsRow: [
      'Total',
      pdfCurrency(totalSales),
      '$totalTxns',
      totalTxns > 0 ? pdfCurrency(totalSales / totalTxns) : '—',
      '100%',
      '',
    ],
    rightAlignCols: [1, 2, 3, 4, 5],
  );
}
