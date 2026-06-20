import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/sync/sync_status.dart';

/// Regression coverage for the pull-side tenant bug: synced transactions used
/// to land with a null business_id and so disappeared from the business-scoped
/// report queries. These tests pin the fix and the one-time backfill.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Map<String, dynamic> serverRow({
    required String id,
    String? businessId = 'biz-1',
    String? invoiceNumber = 'INV-202606-000001',
    String createdAt = '2026-06-01T10:00:00.000Z',
  }) {
    return {
      'id': id,
      'business_id': businessId,
      'branch_id': 'branch-1',
      'cashier_id': 'cashier-1',
      'shift_id': null,
      'total_amount': 100.0,
      'tax_amount': 0.0,
      'status': 'completed',
      'payment_method': 'cash',
      'invoice_number': invoiceNumber,
      'created_at': createdAt,
    };
  }

  group('upsertFromServer', () {
    test('carries business_id and invoice_number onto a new row', () async {
      await db.transactionsDao.upsertFromServer(serverRow(id: 'tx-1'));

      final row = await db.transactionsDao.getById('tx-1');
      expect(row, isNotNull);
      expect(row!.businessId, 'biz-1');
      expect(row.invoiceNumber, 'INV-202606-000001');
      expect(row.syncStatus, SyncStatus.synced.toInt());
    });

    test('synced row is visible to the business-scoped report query', () async {
      await db.transactionsDao.upsertFromServer(serverRow(id: 'tx-1'));

      final since = await db.transactionsDao.getTransactionsSince(
        DateTime.utc(2026, 1, 1),
        businessId: 'biz-1',
      );
      expect(since.map((t) => t.id), contains('tx-1'));
    });
  });

  group('backfillNullBusinessId', () {
    test('repairs synced null-business rows and reports the count', () async {
      // Simulate legacy rows pulled before the fix (business_id null).
      await db.transactionsDao.upsertFromServer(
        serverRow(id: 'tx-null', businessId: null),
      );
      expect((await db.transactionsDao.getById('tx-null'))!.businessId, isNull);

      final repaired = await db.transactionsDao.backfillNullBusinessId('biz-1');

      expect(repaired, 1);
      expect((await db.transactionsDao.getById('tx-null'))!.businessId, 'biz-1');
    });

    test('is a no-op once rows already carry a business', () async {
      await db.transactionsDao.upsertFromServer(serverRow(id: 'tx-1'));
      expect(await db.transactionsDao.backfillNullBusinessId('biz-1'), 0);
    });
  });
}
