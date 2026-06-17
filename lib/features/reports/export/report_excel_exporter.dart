import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/export/_excel_saver_stub.dart'
    if (dart.library.io) 'package:pos/features/reports/export/_excel_saver_io.dart'
    if (dart.library.html) 'package:pos/features/reports/export/_excel_saver_web.dart';

// ─── Public entry-point ───────────────────────────────────────────────────────

class ReportExcelExporter {
  /// Builds an .xlsx workbook and saves / downloads it.
  /// Returns the filename (web) or full path (mobile/desktop).
  static Future<String> export({
    required ReportsData data,
    required ReportPeriod period,
    required String businessName,
    required String branchLabel,
  }) async {
    final sheets = [
      _buildSalesSheet(data, businessName, branchLabel, period),
      _buildInventorySheet(data),
      _buildProfitSheet(data),
      if (data.branchStats.isNotEmpty) _buildBranchSheet(data),
      if (data.ingredientItems.isNotEmpty) _buildIngredientsSheet(data),
    ];

    final bytes = _XlsxWriter.encode(sheets);
    final filename = _filename(period);
    return saveAndShareExcel(bytes, filename);
  }

  // ── Sheet builders ──────────────────────────────────────────────────────────

  static _Sheet _buildSalesSheet(
    ReportsData data,
    String businessName,
    String branchLabel,
    ReportPeriod period,
  ) {
    final rows = <_Row>[];

    // ① KPI summary
    rows.add(_headerRow(['Metric', 'Current Period', 'Previous Period', 'Change']));
    rows.add(_kpiRow(0, 'Total Revenue', _cur(data.totalRevenue), _cur(data.prevTotalRevenue), _chg(data.totalRevenue, data.prevTotalRevenue)));
    rows.add(_kpiRow(1, 'Transactions', '${data.totalTransactions}', '${data.prevTotalTransactions}', _delta(data.totalTransactions - data.prevTotalTransactions)));
    rows.add(_kpiRow(2, 'Avg. Ticket', _cur(data.avgTicket), _cur(data.prevAvgTicket), _chg(data.avgTicket, data.prevAvgTicket)));
    rows.add(_kpiRow(3, 'Items Sold', '${data.itemsSold}', '${data.prevItemsSold}', _delta(data.itemsSold - data.prevItemsSold)));
    rows.add(_blankRow(4));

    // ② Sales trend
    rows.add(_sectionRow('Sales Trend'));
    rows.add(_headerRow(['Period', 'Revenue']));
    final trend = data.salesTrend.where((p) => p.label.isNotEmpty).toList();
    double trendTotal = 0;
    for (int i = 0; i < trend.length; i++) {
      trendTotal += trend[i].total;
      rows.add(_Row([
        _Cell(trend[i].label, i.isOdd ? _S.altL : _S.normalL),
        _Cell(_cur(trend[i].total), i.isOdd ? _S.altR : _S.normalR),
      ]));
    }
    rows.add(_totalsRow(['Total', _cur(trendTotal)]));
    rows.add(_blankRow(rows.length));

    // ③ Category breakdown
    rows.add(_sectionRow('Category Breakdown'));
    rows.add(_headerRow(['Category', 'Revenue', '% of Total']));
    final cats = data.categoryBreakdown;
    final catTotal = cats.fold(0.0, (s, c) => s + c.total);
    for (int i = 0; i < cats.length; i++) {
      final pct = catTotal > 0 ? '${(cats[i].total / catTotal * 100).toStringAsFixed(1)}%' : '0%';
      rows.add(_Row([
        _Cell(cats[i].name, i.isOdd ? _S.altL : _S.normalL),
        _Cell(_cur(cats[i].total), i.isOdd ? _S.altR : _S.normalR),
        _Cell(pct, i.isOdd ? _S.altR : _S.normalR),
      ]));
    }
    rows.add(_totalsRow(['Total', _cur(catTotal), '100%']));

    return _Sheet(
      name: 'Sales Report',
      rows: rows,
      colWidths: [28, 18, 18, 15],
      frozenRows: 1,
    );
  }

  static _Sheet _buildInventorySheet(ReportsData data) {
    final rows = <_Row>[];
    rows.add(_headerRow(['Product', 'Status', 'Stock', 'Avg / Day', 'Days Left', 'Notes']));

    for (int i = 0; i < data.inventoryItems.length; i++) {
      final item = data.inventoryItems[i];
      final stock = item.currentStock % 1 == 0
          ? item.currentStock.toInt().toString()
          : item.currentStock.toStringAsFixed(1);
      final avg = item.avgDailySale < 0.01 ? '0' : item.avgDailySale.toStringAsFixed(1);
      final days = item.daysLeft == null
          ? '∞'
          : item.daysLeft! > 999
              ? '999+'
              : item.daysLeft!.toStringAsFixed(1);
      rows.add(_Row([
        _Cell(item.productName, i.isOdd ? _S.altL : _S.normalL),
        _Cell(item.status.label, i.isOdd ? _S.altL : _S.normalL),
        _Cell(stock, i.isOdd ? _S.altR : _S.normalR),
        _Cell(avg, i.isOdd ? _S.altR : _S.normalR),
        _Cell(days, i.isOdd ? _S.altR : _S.normalR),
        _Cell(item.notes ?? '-', i.isOdd ? _S.altL : _S.normalL),
      ]));
    }

    return _Sheet(
      name: 'Inventory',
      rows: rows,
      colWidths: [32, 14, 12, 12, 12, 28],
      frozenRows: 1,
    );
  }

  static _Sheet _buildIngredientsSheet(ReportsData data) {
    final rows = <_Row>[];
    rows.add(_headerRow(['Ingredient', 'Status', 'Unit', 'Stock', 'Consumed', 'Days Left', 'Cost/Unit', 'Total Cost']));

    for (int i = 0; i < data.ingredientItems.length; i++) {
      final item = data.ingredientItems[i];
      final stock = item.currentStock % 1 == 0
          ? item.currentStock.toInt().toString()
          : item.currentStock.toStringAsFixed(1);
      final consumed = item.consumed < 0.01
          ? '0'
          : item.consumed % 1 == 0
          ? item.consumed.toInt().toString()
          : item.consumed.toStringAsFixed(1);
      final days = item.daysLeft == null
          ? '∞'
          : item.daysLeft! > 999
          ? '999+'
          : item.daysLeft!.toStringAsFixed(1);
      final costPer = item.costPerUnit != null
          ? '₱${item.costPerUnit!.toStringAsFixed(2)}'
          : '—';
      final totalCost = item.consumptionCost > 0
          ? '₱${item.consumptionCost.toStringAsFixed(2)}'
          : '—';
      rows.add(_Row([
        _Cell(item.name, i.isOdd ? _S.altL : _S.normalL),
        _Cell(item.status.label, i.isOdd ? _S.altL : _S.normalL),
        _Cell(item.unit ?? 'pcs', i.isOdd ? _S.altL : _S.normalL),
        _Cell(stock, i.isOdd ? _S.altR : _S.normalR),
        _Cell(consumed, i.isOdd ? _S.altR : _S.normalR),
        _Cell(days, i.isOdd ? _S.altR : _S.normalR),
        _Cell(costPer, i.isOdd ? _S.altR : _S.normalR),
        _Cell(totalCost, i.isOdd ? _S.altR : _S.normalR),
      ]));
    }

    return _Sheet(
      name: 'Ingredients',
      rows: rows,
      colWidths: [30, 14, 10, 12, 12, 12, 13, 14],
      frozenRows: 1,
    );
  }

  static _Sheet _buildProfitSheet(ReportsData data) {
    final rows = <_Row>[];

    // ① P&L summary
    rows.add(_headerRow(['Metric', 'Amount']));
    final margin = data.grossRevenue > 0
        ? '${(data.netProfit / data.grossRevenue * 100).toStringAsFixed(1)}%'
        : '0%';
    rows.add(_kpiRow(0, 'Gross Revenue', _cur(data.grossRevenue), '', ''));
    rows.add(_kpiRow(1, 'Cost of Goods (COGS)', _cur(data.costOfGoods), '', ''));
    rows.add(_kpiRow(2, 'Net Profit', _cur(data.netProfit), '', ''));
    rows.add(_kpiRow(3, 'Profit Margin', margin, '', ''));
    rows.add(_blankRow(rows.length));

    // ② Period trend
    rows.add(_sectionRow('Period Breakdown'));
    rows.add(_headerRow(['Period', 'Revenue', 'COGS', 'Net Profit', 'Margin %']));
    final trend = data.profitTrend.where((p) => p.label.isNotEmpty).toList();
    double totRev = 0, totCogs = 0;
    for (int i = 0; i < trend.length; i++) {
      final net = trend[i].revenue - trend[i].cogs;
      final mg = trend[i].revenue > 0 ? '${(net / trend[i].revenue * 100).toStringAsFixed(1)}%' : '0%';
      totRev += trend[i].revenue;
      totCogs += trend[i].cogs;
      rows.add(_Row([
        _Cell(trend[i].label, i.isOdd ? _S.altL : _S.normalL),
        _Cell(_cur(trend[i].revenue), i.isOdd ? _S.altR : _S.normalR),
        _Cell(_cur(trend[i].cogs), i.isOdd ? _S.altR : _S.normalR),
        _Cell(_cur(net), i.isOdd ? _S.altR : _S.normalR),
        _Cell(mg, i.isOdd ? _S.altR : _S.normalR),
      ]));
    }
    final totNet = totRev - totCogs;
    final totMg = totRev > 0 ? '${(totNet / totRev * 100).toStringAsFixed(1)}%' : '0%';
    rows.add(_totalsRow(['Total', _cur(totRev), _cur(totCogs), _cur(totNet), totMg]));

    return _Sheet(
      name: 'Profit & Loss',
      rows: rows,
      colWidths: [24, 18, 18, 18, 14],
      frozenRows: 1,
    );
  }

  static _Sheet _buildBranchSheet(ReportsData data) {
    final rows = <_Row>[];
    rows.add(_headerRow(['Branch', 'Total Sales', 'Transactions', 'Avg. Ticket', 'vs Last Period']));

    double totSales = 0;
    int totTxns = 0;
    for (int i = 0; i < data.branchStats.length; i++) {
      final s = data.branchStats[i];
      totSales += s.totalSales;
      totTxns += s.transactions;
      final vs = '${s.vsLastPeriodPct >= 0 ? '+' : ''}${s.vsLastPeriodPct.toStringAsFixed(1)}%';
      rows.add(_Row([
        _Cell(s.isTop ? '★ ${s.name}' : s.name, i.isOdd ? _S.altL : _S.normalL),
        _Cell(_cur(s.totalSales), i.isOdd ? _S.altR : _S.normalR),
        _Cell('${s.transactions}', i.isOdd ? _S.altR : _S.normalR),
        _Cell(_cur(s.avgTicket), i.isOdd ? _S.altR : _S.normalR),
        _Cell(vs, i.isOdd ? _S.altR : _S.normalR),
      ]));
    }
    rows.add(_totalsRow(['Total', _cur(totSales), '$totTxns', '', '']));

    return _Sheet(
      name: 'Branch Comparison',
      rows: rows,
      colWidths: [26, 18, 15, 18, 18],
      frozenRows: 1,
    );
  }

  // ── Row / cell helpers ──────────────────────────────────────────────────────

  static _Row _headerRow(List<String> labels) => _Row(
        labels.asMap().entries.map((e) => _Cell(e.value, _S.header)).toList(),
      );

  static _Row _sectionRow(String title) => _Row([_Cell(title, _S.section)]);

  static _Row _blankRow(int _) => const _Row([]);

  static _Row _kpiRow(int idx, String label, String cur, String prev, String chg) => _Row([
        _Cell(label, idx.isOdd ? _S.altBoldL : _S.boldL),
        _Cell(cur, idx.isOdd ? _S.altR : _S.normalR),
        if (prev.isNotEmpty) _Cell(prev, idx.isOdd ? _S.altR : _S.normalR),
        if (chg.isNotEmpty) _Cell(chg, idx.isOdd ? _S.altR : _S.normalR),
      ]);

  static _Row _totalsRow(List<String> cells) => _Row(
        cells.asMap().entries.map((e) => _Cell(e.value, e.key == 0 ? _S.totalL : _S.totalR)).toList(),
      );

  // ── Formatters ──────────────────────────────────────────────────────────────

  static String _cur(double v) {
    if (v >= 1000000) return 'PHP ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'PHP ${(v / 1000).toStringAsFixed(2)}k';
    return 'PHP ${v.toStringAsFixed(2)}';
  }

  static String _chg(double cur, double prev) {
    if (prev == 0) return cur > 0 ? '+100%' : '0%';
    final pct = (cur - prev) / prev * 100;
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
  }

  static String _delta(int d) => '${d >= 0 ? '+' : ''}$d';

  static String _filename(ReportPeriod period) {
    final slug = period.label.toLowerCase().replaceAll(' ', '-');
    final now = DateTime.now();
    final stamp = '${now.year}${_p(now.month)}${_p(now.day)}-${_p(now.hour)}${_p(now.minute)}';
    return 'report-$slug-$stamp.xlsx';
  }

  static String _p(int n) => n.toString().padLeft(2, '0');
}

// ─── Style index constants ─────────────────────────────────────────────────────
// These indices map to cellXfs entries in styles.xml (see _XlsxWriter._styles).

abstract class _S {
  static const normalL = 0; // default, left
  static const header = 1;  // brand bg, bold white, left
  static const altL = 2;    // alt row, left
  static const totalL = 3;  // total row bold, left
  static const normalR = 4; // default, right
  static const altR = 5;    // alt row, right
  static const totalR = 6;  // total row bold, right
  static const boldL = 7;   // bold, left (no special bg)
  static const altBoldL = 8;// alt row bold, left
  static const section = 9; // section header (brand soft bg, bold)
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _Cell {
  final String value;
  final int style;
  const _Cell(this.value, this.style);
}

class _Row {
  final List<_Cell> cells;
  const _Row(this.cells);
}

class _Sheet {
  final String name;
  final List<_Row> rows;
  final List<double> colWidths;
  final int? frozenRows;
  const _Sheet({
    required this.name,
    required this.rows,
    required this.colWidths,
    this.frozenRows,
  });
}

// ─── Minimal XLSX writer ──────────────────────────────────────────────────────
// Builds a valid .xlsx (Office Open XML) ZIP without any external xlsx library.

class _XlsxWriter {
  static List<int> encode(List<_Sheet> sheets) {
    final archive = Archive();

    _add(archive, '[Content_Types].xml', _contentTypes(sheets));
    _add(archive, '_rels/.rels', _rootRels());
    _add(archive, 'xl/workbook.xml', _workbook(sheets));
    _add(archive, 'xl/_rels/workbook.xml.rels', _workbookRels(sheets));
    _add(archive, 'xl/styles.xml', _styles());

    for (int i = 0; i < sheets.length; i++) {
      _add(archive, 'xl/worksheets/sheet${i + 1}.xml', _worksheet(sheets[i]));
    }

    return ZipEncoder().encode(archive);
  }

  static void _add(Archive archive, String path, String xml) {
    final bytes = utf8.encode(xml);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  // ── XML parts ───────────────────────────────────────────────────────────────

  static String _contentTypes(List<_Sheet> sheets) {
    final overrides = StringBuffer();
    for (int i = 0; i < sheets.length; i++) {
      overrides.write(
        '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument'
        '.spreadsheetml.worksheet+xml"/>',
      );
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '$overrides'
        '</Types>';
  }

  static String _rootRels() =>
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" '
      'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
      'Target="xl/workbook.xml"/>'
      '</Relationships>';

  static String _workbook(List<_Sheet> sheets) {
    final buf = StringBuffer();
    for (int i = 0; i < sheets.length; i++) {
      buf.write('<sheet name="${_esc(sheets[i].name)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>');
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets>$buf</sheets>'
        '</workbook>';
  }

  static String _workbookRels(List<_Sheet> sheets) {
    final buf = StringBuffer();
    for (int i = 0; i < sheets.length; i++) {
      buf.write(
        '<Relationship Id="rId${i + 1}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
        'Target="worksheets/sheet${i + 1}.xml"/>',
      );
    }
    buf.write(
      '<Relationship Id="rId${sheets.length + 1}" '
      'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
      'Target="styles.xml"/>',
    );
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '$buf'
        '</Relationships>';
  }

  static String _styles() =>
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      // fonts: 0=normal, 1=bold dark, 2=bold white (for header)
      '<fonts count="3">'
      '<font><sz val="10"/><name val="Calibri"/><color rgb="FF0F172A"/></font>'
      '<font><sz val="10"/><b/><name val="Calibri"/><color rgb="FF0F172A"/></font>'
      '<font><sz val="10"/><b/><name val="Calibri"/><color rgb="FFFFFFFF"/></font>'
      '</fonts>'
      // fills: 0,1=required, 2=brand(#557FF4), 3=alt(#F7F9FC), 4=total(#D1E0FF), 5=section(#EAF0FF)
      '<fills count="6">'
      '<fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FF557FF4"/></patternFill></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FFF7F9FC"/></patternFill></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FFD1E0FF"/></patternFill></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FFEAF0FF"/></patternFill></fill>'
      '</fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="10">'
      // 0: normalL
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      // 1: header (bold white, brand bg, left)
      '<xf numFmtId="0" fontId="2" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>'
      // 2: altL
      '<xf numFmtId="0" fontId="0" fillId="3" borderId="0" xfId="0" applyFill="1"/>'
      // 3: totalL (bold, total bg)
      '<xf numFmtId="0" fontId="1" fillId="4" borderId="0" xfId="0" applyFont="1" applyFill="1"/>'
      // 4: normalR
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment horizontal="right"/></xf>'
      // 5: altR
      '<xf numFmtId="0" fontId="0" fillId="3" borderId="0" xfId="0" applyFill="1" applyAlignment="1"><alignment horizontal="right"/></xf>'
      // 6: totalR
      '<xf numFmtId="0" fontId="1" fillId="4" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="right"/></xf>'
      // 7: boldL
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
      // 8: altBoldL
      '<xf numFmtId="0" fontId="1" fillId="3" borderId="0" xfId="0" applyFont="1" applyFill="1"/>'
      // 9: section (bold dark, section-soft bg)
      '<xf numFmtId="0" fontId="1" fillId="5" borderId="0" xfId="0" applyFont="1" applyFill="1"/>'
      '</cellXfs>'
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
      '</styleSheet>';

  static String _worksheet(_Sheet sheet) {
    final buf = StringBuffer();

    // Freeze pane
    final freeze = StringBuffer();
    if (sheet.frozenRows != null && sheet.frozenRows! > 0) {
      freeze.write(
        '<sheetViews><sheetView workbookViewId="0">'
        '<pane ySplit="${sheet.frozenRows}" topLeftCell="A${sheet.frozenRows! + 1}" '
        'activePane="bottomLeft" state="frozen"/>'
        '</sheetView></sheetViews>',
      );
    }

    // Column widths
    final cols = StringBuffer('<cols>');
    for (int i = 0; i < sheet.colWidths.length; i++) {
      cols.write('<col min="${i + 1}" max="${i + 1}" width="${sheet.colWidths[i]}" customWidth="1"/>');
    }
    cols.write('</cols>');

    // Sheet data
    buf.write('<sheetData>');
    int rowNum = 1;
    for (final row in sheet.rows) {
      if (row.cells.isEmpty) {
        buf.write('<row r="$rowNum"/>');
      } else {
        buf.write('<row r="$rowNum">');
        for (int c = 0; c < row.cells.length; c++) {
          final cell = row.cells[c];
          final ref = '${_col(c)}$rowNum';
          buf.write('<c r="$ref" t="inlineStr" s="${cell.style}"><is><t>${_esc(cell.value)}</t></is></c>');
        }
        buf.write('</row>');
      }
      rowNum++;
    }
    buf.write('</sheetData>');

    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '$freeze$cols$buf'
        '</worksheet>';
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static String _col(int idx) {
    if (idx < 26) return String.fromCharCode(65 + idx);
    return '${String.fromCharCode(64 + idx ~/ 26)}${String.fromCharCode(65 + idx % 26)}';
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
