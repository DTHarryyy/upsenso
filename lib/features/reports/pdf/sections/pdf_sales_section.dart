import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart'
    show fmtPct, pctChange;

List<pw.Widget> buildSalesSection(ReportsData data) {
  final revChg = pctChange(data.totalRevenue, data.prevTotalRevenue);
  final txnChg = pctChange(
      data.totalTransactions.toDouble(), data.prevTotalTransactions.toDouble());
  final ticketChg = pctChange(data.avgTicket, data.prevAvgTicket);
  final itemsChg = pctChange(
      data.itemsSold.toDouble(), data.prevItemsSold.toDouble());

  return [
    PdfS.sectionHeader('Sales Report'),

    // ── Stat boxes ───────────────────────────────────────────────────────────
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Total Revenue',
            value: pdfCurrency(data.totalRevenue),
            change: '${fmtPct(revChg)} vs prev period',
            isPositive: revChg >= 0,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Transactions',
            value: data.totalTransactions.toString(),
            change: '${fmtPct(txnChg)} vs prev period',
            isPositive: txnChg >= 0,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Avg. Ticket',
            value: pdfCurrency(data.avgTicket),
            change: '${fmtPct(ticketChg)} vs prev period',
            isPositive: ticketChg >= 0,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Items Sold',
            value: data.itemsSold.toString(),
            change: '${fmtPct(itemsChg)} vs prev period',
            isPositive: itemsChg >= 0,
          ),
        ),
      ],
    ),

    // ── Sales trend ──────────────────────────────────────────────────────────
    if (data.salesTrend.isNotEmpty) ...[
      PdfS.subHeader('Sales Trend'),
      _salesTrendTable(data),
    ],

    // ── Category breakdown ───────────────────────────────────────────────────
    if (data.categoryBreakdown.isNotEmpty) ...[
      PdfS.subHeader('Sales by Category'),
      _categoryTable(data),
    ],
  ];
}

pw.Widget _salesTrendTable(ReportsData data) {
  final points =
      data.salesTrend.where((p) => p.label.isNotEmpty).toList();
  return pw.Table(
    columnWidths: {
      0: const pw.FlexColumnWidth(2.5),
      1: const pw.FlexColumnWidth(2),
    },
    children: [
      PdfS.tableHeaderRow(['Period', 'Revenue']),
      ...List.generate(points.length, (i) {
        final p = points[i];
        return PdfS.tableDataRow([p.label, pdfCurrency(p.total)], i);
      }),
    ],
  );
}

pw.Widget _categoryTable(ReportsData data) {
  final total =
      data.categoryBreakdown.fold(0.0, (sum, c) => sum + c.total);
  return pw.Table(
    columnWidths: {
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FlexColumnWidth(1.5),
    },
    children: [
      PdfS.tableHeaderRow(['Category', 'Revenue', '% of Total']),
      ...List.generate(data.categoryBreakdown.length, (i) {
        final c = data.categoryBreakdown[i];
        final pct = total > 0 ? c.total / total * 100 : 0.0;
        return PdfS.tableDataRow(
          [c.name, pdfCurrency(c.total), '${pct.toStringAsFixed(1)}%'],
          i,
        );
      }),
    ],
  );
}
