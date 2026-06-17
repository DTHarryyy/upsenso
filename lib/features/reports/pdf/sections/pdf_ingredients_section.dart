import 'package:pdf/widgets.dart' as pw;
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/pdf/report_pdf_styles.dart';

List<pw.Widget> buildIngredientsSection(ReportsData data) {
  return [
    PdfS.sectionHeader(
      '05',
      'Ingredient Health',
      description:
          'Stock levels and recipe consumption for tracked ingredients.',
    ),

    PdfS.metricRow([
      PdfMetric('Total Ingredients', '${data.totalIngredients}'),
      PdfMetric(
        'Low Stock',
        '${data.lowIngredientCount}',
        change: data.lowIngredientCount > 0 ? 'Requires restocking' : 'All good',
        isPositive: data.lowIngredientCount == 0,
      ),
      PdfMetric(
        'Not Used',
        '${data.ingredientItems.where((i) => i.consumed == 0).length}',
        change: 'No consumption this period',
        isPositive: false,
      ),
      PdfMetric(
        'Consumption Cost',
        pdfCurrency(data.ingredientConsumptionCost),
        change: 'Total ingredient cost used',
        isPositive: true,
      ),
    ]),

    if (data.ingredientItems.isNotEmpty) ...[
      PdfS.subHead('Ingredient Detail'),
      _ingredientTable(data),
    ] else ...[
      PdfS.sp(12),
      pw.Center(
        child: pw.Text(
          'No ingredients found for this business.',
          style: PdfS.bodySmall(),
        ),
      ),
    ],
  ];
}

pw.Widget _ingredientTable(ReportsData data) {
  return PdfS.financialTable(
    columnWidths: {
      0: const pw.FlexColumnWidth(3.5),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(1.0),
      3: const pw.FlexColumnWidth(1.2),
      4: const pw.FlexColumnWidth(1.2),
      5: const pw.FlexColumnWidth(1.2),
    },
    headers: ['Ingredient', 'Status', 'Unit', 'Stock', 'Consumed', 'Days Left'],
    rows: data.ingredientItems.map((item) {
      final stock = item.currentStock % 1 == 0
          ? item.currentStock.toInt().toString()
          : item.currentStock.toStringAsFixed(1);
      final consumed = item.consumed < 0.01
          ? '0'
          : item.consumed % 1 == 0
          ? item.consumed.toInt().toString()
          : item.consumed.toStringAsFixed(1);
      final days = item.daysLeft == null
          ? 'Unlimited'
          : item.daysLeft! > 999
          ? '999+ days'
          : '${item.daysLeft!.toStringAsFixed(0)} days';
      return [
        item.name,
        item.status.label,
        item.unit ?? 'pcs',
        stock,
        consumed,
        days,
      ];
    }).toList(),
    rightAlignCols: [3, 4, 5],
  );
}
