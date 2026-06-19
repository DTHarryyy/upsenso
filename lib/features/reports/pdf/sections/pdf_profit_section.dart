import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart'
    show pctChange;

List<pw.Widget> buildProfitSection(ReportsData data) {
  final profitChg = pctChange(data.netProfit, data.prevNetProfit);
  // Profit math excludes collected tax. Net revenue is the profit base
  // (netProfit = netRevenue - COGS), derived without a model change.
  final netRevenue = data.netProfit + data.costOfGoods;
  final margin = netRevenue > 0 ? data.netProfit / netRevenue * 100 : 0.0;
  final cogsRatio = netRevenue > 0 ? data.costOfGoods / netRevenue * 100 : 0.0;

  String s(double v) =>
      '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}% vs prev';

  return [
    PdfS.sectionHeader(
      '03',
      'Profit & Loss',
      description:
          'Gross revenue, cost of goods, and net profit with period-over-period comparisons.',
    ),

    // ── P&L Summary KPIs ────────────────────────────────────────────────────
    PdfS.metricRow([
      PdfMetric('Net Revenue', pdfCurrency(netRevenue)),
      PdfMetric('Cost of Goods', pdfCurrency(data.costOfGoods),
          change: '${cogsRatio.toStringAsFixed(1)}% of revenue',
          isPositive: false),
      PdfMetric(
        'Net Profit',
        pdfCurrency(data.netProfit),
        change: s(profitChg),
        isPositive: profitChg >= 0,
      ),
      PdfMetric('Profit Margin', '${margin.toStringAsFixed(1)}%',
          change: margin >= 20
              ? 'Healthy margin'
              : margin >= 10
                  ? 'Moderate margin'
                  : 'Low margin',
          isPositive: margin >= 15),
    ]),

    // ── P&L summary table ────────────────────────────────────────────────────
    PdfS.subHead('Profit & Loss Statement'),
    PdfS.financialTable(
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
      },
      headers: ['Line Item', 'Amount', '% of Revenue'],
      rows: [
        [
          'Net Revenue',
          pdfCurrency(netRevenue),
          '100%',
        ],
        [
          'Cost of Goods (COGS)',
          pdfCurrency(data.costOfGoods),
          '${cogsRatio.toStringAsFixed(1)}%',
        ],
        [
          'Gross Profit',
          pdfCurrency(netRevenue - data.costOfGoods),
          '${(100 - cogsRatio).toStringAsFixed(1)}%',
        ],
      ],
      totalsRow: [
        'Net Profit',
        pdfCurrency(data.netProfit),
        '${margin.toStringAsFixed(1)}%',
      ],
      rightAlignCols: [1, 2],
    ),

    // ── Period trend table ───────────────────────────────────────────────────
    if (data.profitTrend.isNotEmpty) ...[
      PdfS.subHead('Period Breakdown'),
      _profitTrendTable(data),
    ],
  ];
}

pw.Widget _profitTrendTable(ReportsData data) {
  // Totals span every bucket; labels are blanked only for axis readability,
  // so summing over the displayed rows would silently drop most days.
  final pts = data.profitTrend.where((p) => p.label.isNotEmpty).toList();
  double totRev = 0, totCogs = 0;
  for (final p in data.profitTrend) {
    totRev += p.revenue;
    totCogs += p.cogs;
  }
  final totNet = totRev - totCogs;
  final totMargin =
      totRev > 0 ? '${(totNet / totRev * 100).toStringAsFixed(1)}%' : '—';

  return PdfS.financialTable(
    columnWidths: {
      0: const pw.FlexColumnWidth(2),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FlexColumnWidth(2),
      4: const pw.FlexColumnWidth(1.4),
    },
    headers: ['Period', 'Revenue', 'COGS', 'Net Profit', 'Margin'],
    rows: pts.map((p) {
      final net = p.revenue - p.cogs;
      final mg = p.revenue > 0
          ? '${(net / p.revenue * 100).toStringAsFixed(1)}%'
          : '—';
      return [
        p.label,
        pdfCurrency(p.revenue),
        pdfCurrency(p.cogs),
        pdfCurrency(net),
        mg,
      ];
    }).toList(),
    totalsRow: [
      'Total',
      pdfCurrency(totRev),
      pdfCurrency(totCogs),
      pdfCurrency(totNet),
      totMargin,
    ],
    rightAlignCols: [1, 2, 3, 4],
  );
}
