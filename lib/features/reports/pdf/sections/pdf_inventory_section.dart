import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';

List<pw.Widget> buildInventorySection(ReportsData data) {
  return [
    PdfS.sectionHeader(
      '02',
      'Inventory Health',
      description:
          'Stock levels, movement rates, and supply runway for tracked products.',
    ),

    // ── Summary KPIs ────────────────────────────────────────────────────────
    PdfS.metricRow([
      PdfMetric(
        'Low Stock Items',
        '${data.lowStockCount}',
        change: data.lowStockCount > 0 ? 'Requires restocking' : 'All good',
        isPositive: data.lowStockCount == 0,
      ),
      PdfMetric('Fast Movers', '${data.fastMoversCount}',
          change: 'Selling quickly', isPositive: true),
      PdfMetric(
        'Dead Stock',
        '${data.deadStockCount}',
        change: 'No recent sales',
        isPositive: data.deadStockCount == 0,
      ),
      PdfMetric('Total SKUs', '${data.totalSKUs}'),
    ]),

    // ── Inventory status table ───────────────────────────────────────────────
    if (data.inventoryItems.isNotEmpty) ...[
      PdfS.subHead('Product Status Detail'),
      _inventoryTable(data),
    ] else ...[
      PdfS.sp(12),
      pw.Center(
        child: pw.Text(
          'No tracked inventory items for this period.',
          style: PdfS.bodySmall(),
        ),
      ),
    ],
  ];
}

pw.Widget _inventoryTable(ReportsData data) {
  return PdfS.financialTable(
    columnWidths: {
      0: const pw.FlexColumnWidth(3.5),
      1: const pw.FlexColumnWidth(1.4),
      2: const pw.FlexColumnWidth(1.2),
      3: const pw.FlexColumnWidth(1.2),
      4: const pw.FlexColumnWidth(1.2),
      5: const pw.FlexColumnWidth(2.5),
    },
    headers: ['Product', 'Status', 'Stock', 'Avg/Day', 'Days Left', 'Notes'],
    rows: data.inventoryItems.map((item) {
      final stock = item.currentStock % 1 == 0
          ? item.currentStock.toInt().toString()
          : item.currentStock.toStringAsFixed(1);
      final avg = item.avgDailySale < 0.01
          ? '0'
          : item.avgDailySale.toStringAsFixed(1);
      final days = item.daysLeft == null
          ? 'Unlimited'
          : item.daysLeft! > 999
              ? '999+ days'
              : '${item.daysLeft!.toStringAsFixed(0)} days';
      return [
        item.productName,
        item.status.label,
        stock,
        avg,
        days,
        item.notes ?? '—',
      ];
    }).toList(),
    rightAlignCols: [2, 3, 4],
    mutedCols: [5],
  );
}

// Status colour helper (for future chart use)
PdfColor statusColor(InventoryStatusType s) => switch (s) {
      InventoryStatusType.low => PdfS.error,
      InventoryStatusType.warning => PdfS.warning,
      InventoryStatusType.ok => PdfS.success,
      InventoryStatusType.slowMoving => PdfS.accent,
    };
