import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/devices_dao.dart';
import 'package:pos/core/sync/sync_status.dart';

/// The normalized device directory (2026-07-03 fix plan §4c): the label is
/// resolved once per uid and never flaps thereafter, and refreshes re-queue
/// the row for sync.
void main() {
  late AppDatabase db;
  late DevicesDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = DevicesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('first touch inserts; later touches keep the label but re-queue sync',
      () async {
    await dao.touch(
      deviceUid: 'uid-1',
      businessId: 'biz1',
      label: 'Web · chrome',
      platform: 'web',
    );
    final first = await dao.getByUid('uid-1');
    expect(first, isNotNull);
    expect(first!.label, 'Web · chrome');
    expect(first.syncStatus, SyncStatus.pendingUpload.toInt());

    // A later cold start mis-detects the browser as safari — the stored label
    // must NOT flap (the exact 2026-07-03 label instability).
    await dao.touch(
      deviceUid: 'uid-1',
      businessId: 'biz1',
      label: 'Web · safari',
      platform: 'web',
    );
    final second = await dao.getByUid('uid-1');
    expect(second!.label, 'Web · chrome', reason: 'first-resolved label is stable');
    expect(second.syncStatus, SyncStatus.pendingUpdate.toInt());
  });

  test('labelsByBusiness maps uid → stable label', () async {
    await dao.touch(
      deviceUid: 'uid-1',
      businessId: 'biz1',
      label: 'Pixel 7 · Android 14',
      platform: 'android',
    );
    await dao.touch(
      deviceUid: 'uid-2',
      businessId: 'biz1',
      label: 'Web · chrome',
      platform: 'web',
    );
    final labels = await dao.labelsByBusiness('biz1');
    expect(labels, {'uid-1': 'Pixel 7 · Android 14', 'uid-2': 'Web · chrome'});
  });
}
