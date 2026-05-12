import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart'
    show pctChange;

/// Returns a full cover page with:
///  • Accent top bar
///  • Business name + report title
///  • Metadata row (period / branch / generated)
///  • Executive summary (large KPIs in two rows)
///  • Inventory overview (small KPIs)
///  • Confidentiality notice
///
/// Intended to be rendered as a dedicated [pw.Page] — not mixed into MultiPage.
pw.Widget buildCoverPage({
  required String businessName,
  required String branchLabel,
  required ReportPeriod period,
  required ReportsData data,
}) {
  final now = DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = now.hour > 12
      ? now.hour - 12
      : (now.hour == 0 ? 12 : now.hour);
  final ampm = now.hour >= 12 ? 'PM' : 'AM';
  final dateStr =
      '${months[now.month - 1]} ${now.day}, ${now.year}  $h:${now.minute.toString().padLeft(2, '0')} $ampm';

  // Change helpers
  String chg(double cur, double prev) {
    final pct = pctChange(cur, prev);
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}% vs prev period';
  }

  String delta(int d) =>
      '${d >= 0 ? '+' : ''}$d vs prev period';

  final margin = data.grossRevenue > 0
      ? '${(data.netProfit / data.grossRevenue * 100).toStringAsFixed(1)}%'
      : '—';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // ── Top accent bar ──────────────────────────────────────────────────────
      pw.Container(height: 4, color: PdfS.accent),
      PdfS.sp(32),

      // ── Brand + Title ───────────────────────────────────────────────────────
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo block – coloured square with initial
          pw.Container(
            width: 48,
            height: 48,
            color: PdfS.accent,
            child: pw.Center(
              child: pw.Text(
                businessName.isNotEmpty
                    ? businessName.trim()[0].toUpperCase()
                    : 'B',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (businessName.isNotEmpty)
                pw.Text(
                  businessName.toUpperCase(),
                  style: PdfS.headlineS(),
                ),
              PdfS.sp(4),
              pw.Text('Business Analytics Report', style: PdfS.display()),
            ],
          ),
        ],
      ),

      PdfS.sp(24),
      PdfS.heavyRule(),
      PdfS.sp(16),

      // ── Metadata row ────────────────────────────────────────────────────────
      pw.Row(
        children: [
          PdfS.metaBlock('REPORTING PERIOD', period.label),
          pw.SizedBox(width: 48),
          PdfS.metaBlock('BRANCH / LOCATION', branchLabel),
          pw.SizedBox(width: 48),
          PdfS.metaBlock('PREPARED ON', dateStr),
        ],
      ),

      PdfS.sp(20),
      PdfS.rule(),
      PdfS.sp(24),

      // ── Executive Summary heading ────────────────────────────────────────────
      pw.Text('EXECUTIVE SUMMARY', style: PdfS.subsection()),
      PdfS.sp(16),

      // ── Primary KPIs ─────────────────────────────────────────────────────────
      PdfS.metricRow([
        PdfMetric(
          'Total Revenue',
          pdfCurrency(data.totalRevenue),
          change: chg(data.totalRevenue, data.prevTotalRevenue),
          isPositive: data.totalRevenue >= data.prevTotalRevenue,
        ),
        PdfMetric(
          'Transactions',
          '${data.totalTransactions}',
          change: delta(data.totalTransactions - data.prevTotalTransactions),
          isPositive: data.totalTransactions >= data.prevTotalTransactions,
        ),
        PdfMetric(
          'Net Profit',
          pdfCurrency(data.netProfit),
          change: chg(data.netProfit, data.prevNetProfit),
          isPositive: data.netProfit >= data.prevNetProfit,
        ),
      ]),

      PdfS.sp(14),
      PdfS.rule(),
      PdfS.sp(14),

      // ── Secondary KPIs ────────────────────────────────────────────────────────
      PdfS.metricRow([
        PdfMetric(
          'Average Order Value',
          pdfCurrency(data.avgTicket),
          change: chg(data.avgTicket, data.prevAvgTicket),
          isPositive: data.avgTicket >= data.prevAvgTicket,
        ),
        PdfMetric('Gross Margin', margin),
        PdfMetric(
          'Items Sold',
          '${data.itemsSold}',
          change: delta(data.itemsSold - data.prevItemsSold),
          isPositive: data.itemsSold >= data.prevItemsSold,
        ),
      ]),

      PdfS.sp(24),
      PdfS.rule(),
      PdfS.sp(20),

      // ── Inventory overview ────────────────────────────────────────────────────
      pw.Text('INVENTORY OVERVIEW', style: PdfS.subsection()),
      PdfS.sp(14),

      PdfS.metricRow([
        PdfMetric(
          'Low Stock Items',
          '${data.lowStockCount}',
          change: data.lowStockCount > 0 ? 'Needs restocking' : 'All good',
          isPositive: data.lowStockCount == 0,
        ),
        PdfMetric(
          'Fast Movers',
          '${data.fastMoversCount}',
          change: 'Selling quickly',
          isPositive: true,
        ),
        PdfMetric(
          'Dead Stock',
          '${data.deadStockCount}',
          change: 'No recent sales',
          isPositive: data.deadStockCount == 0,
        ),
        PdfMetric('Total SKUs', '${data.totalSKUs}'),
      ]),

      pw.Spacer(),

      // ── Bottom ────────────────────────────────────────────────────────────────
      PdfS.rule(),
      PdfS.sp(8),
      PdfS.confidentialFooter(),
    ],
  );
}
