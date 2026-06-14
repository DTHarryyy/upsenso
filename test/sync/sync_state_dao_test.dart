import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/sync_state_dao.dart';

// Delta-sync: the per-entity/per-business (timestamp, id) keyset cursor store.
void main() {
  late AppDatabase db;
  late SyncStateDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SyncStateDao(db);
  });

  tearDown(() async => db.close());

  test('unset cursor is (null, null) — signals a full pull', () async {
    final w = await dao.getWatermark('products', 'biz');
    expect(w.ts, isNull);
    expect(w.id, isNull);
  });

  // Drift reads timestamps back in local time; assert the same instant rather
  // than the same UTC-flagged object (DateTime.== also compares isUtc).
  test('set then read returns the stored instant and id', () async {
    final ts = DateTime.utc(2026, 6, 14, 10, 30);
    await dao.setWatermark('products', 'biz', ts, 'row-1');
    final w = await dao.getWatermark('products', 'biz');
    expect(w.ts!.isAtSameMomentAs(ts), isTrue);
    expect(w.id, 'row-1');
  });

  test('cursor is scoped per entity and per business', () async {
    await dao.setWatermark('products', 'biz', DateTime.utc(2026, 1, 1), 'p1');
    await dao.setWatermark(
        'transactions', 'biz', DateTime.utc(2026, 2, 2), 't1');

    expect((await dao.getWatermark('products', 'biz')).id, 'p1');
    expect((await dao.getWatermark('transactions', 'biz')).id, 't1');
    expect((await dao.getWatermark('products', 'other-biz')).ts, isNull);
  });

  test('setWatermark advances the cursor (timestamp and id)', () async {
    await dao.setWatermark('products', 'biz', DateTime.utc(2026, 1, 1), 'a');
    final advanced = DateTime.utc(2026, 3, 3);
    await dao.setWatermark('products', 'biz', advanced, 'z');
    final w = await dao.getWatermark('products', 'biz');
    expect(w.ts!.isAtSameMomentAs(advanced), isTrue);
    expect(w.id, 'z');
  });

  test('clearAll resets cursors back to full-pull state', () async {
    await dao.setWatermark('products', 'biz', DateTime.utc(2026, 1, 1), 'a');
    await dao.clearAll();
    expect((await dao.getWatermark('products', 'biz')).ts, isNull);
  });
}
