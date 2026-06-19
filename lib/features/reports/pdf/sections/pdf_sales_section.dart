import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart'
    show pctChange;

List<pw.Widget> buildSalesSection(ReportsData data) {
  final revChg = pctChange(data.totalRevenue, data.prevTotalRevenue);
  final txnChg = pctChange(
      data.totalTransactions.toDouble(), data.prevTotalTransactions.toDouble());
  final tickChg = pctChange(data.avgTicket, data.prevAvgTicket);
  final itemChg = pctChange(
      data.itemsSold.toDouble(), data.prevItemsSold.toDouble());

  String s(double v) =>
      '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}% vs prev';

  return [
    // ── Section header ─────────────────────────────────────────────────────
    PdfS.sectionHeader(
      '01',
      'Sales Performance',
      description:
          'Revenue, transaction volume, and average order value for the reporting period.',
    ),

    // ── KPI metrics ────────────────────────────────────────────────────────
    PdfS.metricRow([
      PdfMetric('Total Revenue', pdfCurrency(data.totalRevenue),
          change: s(revChg), isPositive: revChg >= 0),
      PdfMetric('Transactions', '${data.totalTransactions}',
          change: s(txnChg), isPositive: txnChg >= 0),
      PdfMetric('Avg. Order Value', pdfCurrency(data.avgTicket),
          change: s(tickChg), isPositive: tickChg >= 0),
      PdfMetric('Items Sold', '${data.itemsSold}',
          change: s(itemChg), isPositive: itemChg >= 0),
    ]),

    // ── Period trend table ─────────────────────────────────────────────────
    if (data.salesTrend.isNotEmpty) ...[
      PdfS.subHead('Period Breakdown'),
      _salesTrendTable(data),
    ],

    // ── Category breakdown ─────────────────────────────────────────────────
    if (data.categoryBreakdown.isNotEmpty) ...[
      PdfS.subHead('Sales by Category'),
      _categoryTable(data),
    ],
  ];
}

pw.Widget _salesTrendTable(ReportsData data) {
  // Total spans every bucket; labels are blanked only for axis readability,
  // so summing the displayed rows would drop most days from the total.
  final pts = data.salesTrend.where((p) => p.label.isNotEmpty).toList();
  final total = data.salesTrend.fold(0.0, (s, p) => s + p.total);

  return PdfS.financialTable(
    columnWidths: {
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(2),
    },
    headers: ['Period', 'Revenue'],
    rows: pts.map((p) => [p.label, pdfCurrency(p.total)]).toList(),
    totalsRow: ['Total', pdfCurrency(total)],
    rightAlignCols: [1],
  );
}

pw.Widget _categoryTable(ReportsData data) {
  final total = data.categoryBreakdown.fold(0.0, (s, c) => s + c.total);

  return PdfS.financialTable(
    columnWidths: {
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FlexColumnWidth(1.5),
    },
    headers: ['Category', 'Revenue', '% of Total'],
    rows: data.categoryBreakdown.map((c) {
      final pct = total > 0 ? c.total / total * 100 : 0.0;
      return [c.name, pdfCurrency(c.total), '${pct.toStringAsFixed(1)}%'];
    }).toList(),
    totalsRow: ['Total', pdfCurrency(total), '100%'],
    rightAlignCols: [1, 2],
  );
}
