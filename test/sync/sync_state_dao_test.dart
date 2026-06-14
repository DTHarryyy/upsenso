import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/sync_state_dao.dart';

// Delta-sync Phase 0: the per-entity/per-business watermark store.
void main() {
  late AppDatabase db;
  late SyncStateDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SyncStateDao(db);
  });

  tearDown(() async => db.close());

  test('unset watermark is null (signals a full pull)', () async {
    expect(await dao.getWatermark('products', 'biz'), isNull);
  });

  // Drift reads timestamps back in local time; assert the same instant rather
  // than the same UTC-flagged object (DateTime.== also compares isUtc).
  test('set then read returns the stored instant', () async {
    final ts = DateTime.utc(2026, 6, 14, 10, 30);
    await dao.setWatermark('products', 'biz', ts);
    final got = await dao.getWatermark('products', 'biz');
    expect(got!.isAtSameMomentAs(ts), isTrue);
  });

  test('watermark is scoped per entity and per business', () async {
    final a = DateTime.utc(2026, 1, 1);
    final b = DateTime.utc(2026, 2, 2);
    await dao.setWatermark('products', 'biz', a);
    await dao.setWatermark('transactions', 'biz', b);

    expect((await dao.getWatermark('products', 'biz'))!.isAtSameMomentAs(a),
        isTrue);
    expect((await dao.getWatermark('transactions', 'biz'))!.isAtSameMomentAs(b),
        isTrue);
    expect(await dao.getWatermark('products', 'other-biz'), isNull);
  });

  test('setWatermark overwrites the previous value (advances the cursor)',
      () async {
    await dao.setWatermark('products', 'biz', DateTime.utc(2026, 1, 1));
    final advanced = DateTime.utc(2026, 3, 3);
    await dao.setWatermark('products', 'biz', advanced);
    expect((await dao.getWatermark('products', 'biz'))!.isAtSameMomentAs(advanced),
        isTrue);
  });

  test('clearAll resets watermarks back to full-pull state', () async {
    await dao.setWatermark('products', 'biz', DateTime.utc(2026, 1, 1));
    await dao.clearAll();
    expect(await dao.getWatermark('products', 'biz'), isNull);
  });
}
