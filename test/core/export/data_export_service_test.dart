import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/export/data_export_service.dart';

/// The audit trail is recorded on every tier but only Growth gets the in-app
/// viewer. That gate is only defensible while the always-free Data Export can
/// still hand the owner their trail (§4.7 "never trap data" + BIR
/// retrievability) — so these tests guard the escape hatch, not the paywall.
void main() {
  late AppDatabase db;
  late DataExportService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = DataExportService(db);
  });

  tearDown(() => db.close());

  Future<void> insertAuditRow({required String description}) {
    return db.into(db.auditLogsTable).insert(
          AuditLogsTableCompanion.insert(
            id: 'audit-1',
            businessId: 'biz-1',
            branchId: 'br-1',
            userId: 'u1',
            actionType: 'sale.void',
            entityType: 'transaction',
            description: description,
            entityId: const Value('txn-9'),
          ),
        );
  }

  test('audit_logs is part of the export bundle on every tier', () {
    expect(DataExportService.exportedTables, contains('audit_logs'));
  });

  test('audit rows reach the CSV bundle with no entitlement check', () async {
    await insertAuditRow(description: 'Voided sale #1042');

    final bundle = await service.buildCsvBundle();

    expect(bundle.keys, contains('audit_logs'));
    expect(bundle['audit_logs'], contains('Voided sale #1042'));
    expect(bundle['audit_logs'], contains('sale.void'));
  });

  test('empty tables are skipped rather than exported as headers', () async {
    final bundle = await service.buildCsvBundle();
    expect(bundle, isEmpty);
  });

  test('values containing commas are quoted so the CSV stays parseable',
      () async {
    await insertAuditRow(description: 'Voided sale, refunded ₱1,200');

    final bundle = await service.buildCsvBundle();

    expect(bundle['audit_logs'], contains('"Voided sale, refunded ₱1,200"'));
  });
}
