import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';

/// Regression coverage for the invoice number format change: numbers are now
/// INV-NNNNNN (single continuously-rising counter, no calendar month), so the
/// number always fits a 58mm receipt line without truncation.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('nextLocalInvoiceNumber', () {
    test('produces sequential INV-NNNNNN numbers with no calendar segment', () async {
      final first = await db.invoiceSequencesDao
          .nextLocalInvoiceNumber('biz-1', 'seq');
      final second = await db.invoiceSequencesDao
          .nextLocalInvoiceNumber('biz-1', 'seq');

      expect(first, 'INV-000001');
      expect(second, 'INV-000002');
    });

    test('never repeats a number for the same business+key', () async {
      final seen = <String>{};
      for (var i = 0; i < 20; i++) {
        seen.add(await db.invoiceSequencesDao.nextLocalInvoiceNumber('biz-1', 'seq'));
      }
      expect(seen.length, 20);
    });

    test('keeps independent counters per business', () async {
      final bizA = await db.invoiceSequencesDao.nextLocalInvoiceNumber('biz-a', 'seq');
      final bizB = await db.invoiceSequencesDao.nextLocalInvoiceNumber('biz-b', 'seq');

      expect(bizA, 'INV-000001');
      expect(bizB, 'INV-000001');
    });
  });

  group('syncFromServer', () {
    test('advances the local counter past a higher server value', () async {
      await db.invoiceSequencesDao.nextLocalInvoiceNumber('biz-1', 'seq'); // -> 1
      await db.invoiceSequencesDao.syncFromServer(
        businessId: 'biz-1',
        monthKey: 'seq',
        serverValue: 50,
      );

      final next = await db.invoiceSequencesDao.nextLocalInvoiceNumber('biz-1', 'seq');
      expect(next, 'INV-000051');
    });

    test('never moves the counter backwards', () async {
      await db.invoiceSequencesDao.nextLocalInvoiceNumber('biz-1', 'seq'); // -> 1
      await db.invoiceSequencesDao.syncFromServer(
        businessId: 'biz-1',
        monthKey: 'seq',
        serverValue: 5,
      );
      await db.invoiceSequencesDao.syncFromServer(
        businessId: 'biz-1',
        monthKey: 'seq',
        serverValue: 2, // lower than current — must be ignored
      );

      final next = await db.invoiceSequencesDao.nextLocalInvoiceNumber('biz-1', 'seq');
      expect(next, 'INV-000006');
    });
  });
}
