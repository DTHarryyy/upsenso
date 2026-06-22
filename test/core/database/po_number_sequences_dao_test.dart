import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';

/// Sequential, gapless, per-business PO numbers — the offline counter backing
/// PoNumberService. Mirrors invoice_sequences_dao_test.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('produces PO-YYYYMM-NNNN and increments', () async {
    final first =
        await db.poNumberSequencesDao.nextLocalPoNumber('biz-1', '202606');
    final second =
        await db.poNumberSequencesDao.nextLocalPoNumber('biz-1', '202606');
    expect(first, 'PO-202606-0001');
    expect(second, 'PO-202606-0002');
  });

  test('counters are isolated per business', () async {
    final a = await db.poNumberSequencesDao.nextLocalPoNumber('biz-a', '202606');
    final b = await db.poNumberSequencesDao.nextLocalPoNumber('biz-b', '202606');
    expect(a, 'PO-202606-0001');
    expect(b, 'PO-202606-0001');
  });

  test('syncFromServer advances the local counter past the server value',
      () async {
    await db.poNumberSequencesDao.nextLocalPoNumber('biz-1', '202606'); // -> 1
    await db.poNumberSequencesDao.syncFromServer(
      businessId: 'biz-1',
      monthKey: '202606',
      serverValue: 5,
    );
    final next =
        await db.poNumberSequencesDao.nextLocalPoNumber('biz-1', '202606');
    expect(next, 'PO-202606-0006');
  });
}
