import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';

List<pw.Widget> buildInventorySection(ReportsData data) {
  return [
    PdfS.sectionHeader('Inventory Health'),

    // ── Summary stat boxes ───────────────────────────────────────────────────
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Low Stock Items',
            value: data.lowStockCount.toString(),
            change: 'Needs restocking soon',
            isPositive: false,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Fast Movers',
            value: data.fastMoversCount.toString(),
            change: 'Selling quickly',
            isPositive: true,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Dead Stock',
            value: data.deadStockCount.toString(),
            change: 'No recent sales',
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: PdfS.statBox(
            label: 'Total SKUs',
            value: data.totalSKUs.toString(),
          ),
        ),
      ],
    ),

    // ── Inventory status table ───────────────────────────────────────────────
    if (data.inventoryItems.isNotEmpty) ...[
      PdfS.subHeader('Inventory Status'),
      pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(3.5),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(1.2),
          3: const pw.FlexColumnWidth(1.2),
          4: const pw.FlexColumnWidth(1.2),
          5: const pw.FlexColumnWidth(2.5),
        },
        children: [
          PdfS.tableHeaderRow(
              ['Product', 'Status', 'Stock', 'Avg/Day', 'Days Left', 'Notes']),
          ...List.generate(data.inventoryItems.length, (i) {
            final item = data.inventoryItems[i];
            return PdfS.tableDataRow(
              [
                item.productName,
                item.status.label,
                item.currentStock.toStringAsFixed(0),
                item.avgDailySale.toStringAsFixed(1),
                item.daysLeft != null
                    ? item.daysLeft!.toStringAsFixed(0)
                    : '∞',
                item.notes ?? '—',
              ],
              i,
            );
          }),
        ],
      ),
    ] else ...[
      pw.SizedBox(height: 10),
      pw.Center(
        child: pw.Text(
          'No inventory data available for this period.',
          style: PdfS.bodySmall(),
        ),
      ),
    ],
  ];
}
