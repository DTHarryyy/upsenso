import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/sync/sync_status.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  const biz = 'biz-1';

  group('replaceForVariant', () {
    test('inserts codes as pendingUpload; first is primary; trims + dedups',
        () async {
      await db.productBarcodesDao.replaceForVariant(
        'v1',
        biz,
        [' 111 ', '222', '111', ''],
      );

      final rows = await db.productBarcodesDao.getByVariantId('v1');
      expect(rows.map((r) => r.code).toList(), ['111', '222']);
      expect(rows.first.isPrimary, isTrue); // ordered primary-first
      final all =
          rows.where((r) => r.syncStatus == SyncStatus.pendingUpload.toInt());
      expect(all.length, 2);
    });

    test('reconciles: keeps existing, soft-deletes removed, adds new',
        () async {
      await db.productBarcodesDao.replaceForVariant('v1', biz, ['A', 'B']);
      // Mark them synced to prove "keep" doesn't re-queue unchanged rows.
      for (final r in await db.productBarcodesDao.getByVariantId('v1')) {
        await db.productBarcodesDao
            .updateSyncStatus(id: r.id, status: SyncStatus.synced);
      }

      // Drop B, keep A, add C.
      await db.productBarcodesDao.replaceForVariant('v1', biz, ['A', 'C']);

      final active = await db.productBarcodesDao.getByVariantId('v1');
      expect(active.map((r) => r.code).toSet(), {'A', 'C'});

      final pending = await db.productBarcodesDao.getPendingSync();
      // B is pendingDelete; C is pendingUpload; A stays synced (untouched).
      final byCode = {for (final r in pending) r.code: r};
      expect(byCode['B']!.syncStatus, SyncStatus.pendingDelete.toInt());
      expect(byCode['C']!.syncStatus, SyncStatus.pendingUpload.toInt());
      expect(byCode.containsKey('A'), isFalse);
    });
  });

  group('getByCode / codeExists', () {
    test('resolves an active code and ignores soft-deleted ones', () async {
      await db.productBarcodesDao.replaceForVariant('v1', biz, ['X']);
      expect((await db.productBarcodesDao.getByCode('X', biz))?.variantId, 'v1');
      expect(await db.productBarcodesDao.codeExists('X', biz), isTrue);

      // Remove it → soft-deleted → no longer resolves.
      await db.productBarcodesDao.replaceForVariant('v1', biz, []);
      expect(await db.productBarcodesDao.getByCode('X', biz), isNull);
      expect(await db.productBarcodesDao.codeExists('X', biz), isFalse);
    });

    test('scopes by business and honors excludeVariantId', () async {
      await db.productBarcodesDao.replaceForVariant('v1', biz, ['DUP']);

      expect(await db.productBarcodesDao.codeExists('DUP', 'other-biz'), isFalse);
      expect(await db.productBarcodesDao.codeExists('DUP', biz), isTrue);
      // Editing v1 itself must not see its own code as a collision.
      expect(
        await db.productBarcodesDao
            .codeExists('DUP', biz, excludeVariantId: 'v1'),
        isFalse,
      );
    });
  });
}
