import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pos/core/database/app_database.dart';

/// Local, always-available data export (design §4.1/§4.7).
///
/// Every tier — including Free and lapsed — can export their own data to a file
/// with no entitlement gate whatsoever. On Free this is the safety net for the
/// "data lives only on this device" reality; hiding it is an explicit
/// anti-pattern (§4.7). Produces a readable per-table CSV bundle, zipped, then
/// handed to the platform share sheet (native) or download (web).
class DataExportService {
  final AppDatabase _db;

  DataExportService(this._db);

  /// Business tables worth handing to an owner / accountant.
  static const _tables = <String>[
    'products',
    'product_variants',
    'categories',
    'inventory_levels',
    'transactions',
    'transaction_items',
    'expenses',
    'customers',
    'stock_ledger',
    // The audit trail ships on every tier even though only Growth gets the
    // in-app viewer — the record must always be retrievable (§4.7, and BIR
    // expects it available to a revenue officer).
    'audit_logs',
  ];

  /// Tables this export covers, in bundle order.
  @visibleForTesting
  static List<String> get exportedTables => List.unmodifiable(_tables);

  /// Renders every non-empty table to CSV, keyed by table name. Split out from
  /// [exportCsvBundle] so the bundle's contents can be asserted without the
  /// platform share sheet.
  @visibleForTesting
  Future<Map<String, String>> buildCsvBundle() async {
    final bundle = <String, String>{};
    for (final table in _tables) {
      try {
        final csv = await _tableToCsv(table);
        if (csv == null) continue;
        bundle[table] = csv;
      } catch (e, st) {
        // One bad table must not sink the whole export.
        debugPrint('[DataExport] Error exporting $table: $e\n$st');
      }
    }
    return bundle;
  }

  /// Builds the zip and opens the share/download sheet. Returns false when
  /// there was nothing to export.
  Future<bool> exportCsvBundle() async {
    final archive = Archive();

    for (final entry in (await buildCsvBundle()).entries) {
      final bytes = utf8.encode(entry.value);
      archive.addFile(ArchiveFile('${entry.key}.csv', bytes.length, bytes));
    }

    if (archive.isEmpty) return false;

    final zipped = ZipEncoder().encode(archive);
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final fileName = 'upsenso-export-$stamp.zip';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(zipped),
            name: fileName,
            mimeType: 'application/zip',
          ),
        ],
        fileNameOverrides: [fileName],
        subject: 'UPSENSO data export',
      ),
    );
    return true;
  }

  /// Renders one table as CSV, or null if it has no rows.
  Future<String?> _tableToCsv(String table) async {
    final rows = await _db.customSelect('SELECT * FROM $table').get();
    if (rows.isEmpty) return null;

    final columns = rows.first.data.keys.toList();
    final buffer = StringBuffer();
    buffer.writeln(columns.map(_escape).join(','));
    for (final row in rows) {
      buffer.writeln(columns.map((c) => _escape(row.data[c])).join(','));
    }
    return buffer.toString();
  }

  /// RFC-4180 CSV escaping: wrap in quotes and double any embedded quotes when
  /// the value contains a comma, quote, or newline.
  static String _escape(Object? value) {
    if (value == null) return '';
    final s = value.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n') ||
        s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
