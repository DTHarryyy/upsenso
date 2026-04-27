import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart'
    show fmtPct, pctChange;

List<pw.Widget> buildProfitSection(ReportsData data) {
  final profitChg = pctChange(data.netProfit, data.prevNetProfit);
  final margin = data.grossRevenue > 0
      ? data.netProfit / data.grossRevenue * 100
      : 0.0;

  return [
    PdfS.sectionHeader('Profit Summary'),

    // ── Stat boxes ───────────────────────────────────────────────────────────
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Gross Revenue',
            value: pdfCurrency(data.grossRevenue),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Cost of Goods',
            value: pdfCurrency(data.costOfGoods),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Net Profit',
            value: pdfCurrency(data.netProfit),
            change: '${fmtPct(profitChg)} vs prev period',
            isPositive: profitChg >= 0,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Profit Margin',
            value: '${margin.toStringAsFixed(1)}%',
          ),
        ),
      ],
    ),

    // ── Revenue vs COGS trend table ──────────────────────────────────────────
    if (data.profitTrend.isNotEmpty) ...[
      PdfS.subHeader('Revenue vs COGS Trend'),
      _profitTrendTable(data),
    ],
  ];
}

pw.Widget _profitTrendTable(ReportsData data) {
  final points = data.profitTrend.where((p) => p.label.isNotEmpty).toList();
  return pw.Table(
    columnWidths: {
      0: const pw.FlexColumnWidth(2),
      1: const pw.FlexColumnWidth(1.8),
      2: const pw.FlexColumnWidth(1.8),
      3: const pw.FlexColumnWidth(1.8),
      4: const pw.FlexColumnWidth(1.2),
    },
    children: [
      PdfS.tableHeaderRow(['Period', 'Revenue', 'COGS', 'Profit', 'Margin']),
      ...List.generate(points.length, (i) {
        final p = points[i];
        final profit = p.revenue - p.cogs;
        final m = p.revenue > 0 ? profit / p.revenue * 100 : 0.0;
        return PdfS.tableDataRow(
          [
            p.label,
            pdfCurrency(p.revenue),
            pdfCurrency(p.cogs),
            pdfCurrency(profit),
            '${m.toStringAsFixed(1)}%',
          ],
          i,
        );
      }),
    ],
  );
}
