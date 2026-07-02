import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/sync/sync_status.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> insert({
    required String id,
    String businessId = 'biz-1',
    String name = 'Maria',
    SyncStatus syncStatus = SyncStatus.pendingUpload,
  }) {
    return db.customersDao.insert(
      CustomersTableCompanion.insert(
        id: id,
        businessId: businessId,
        name: name,
        syncStatus: Value(syncStatus.toInt()),
      ),
    );
  }

  group('watchActiveByBusinessId', () {
    test('returns only this business, name-sorted, excludes soft-deleted',
        () async {
      await insert(id: 'c1', name: 'Zoe');
      await insert(id: 'c2', name: 'Ana');
      await insert(id: 'c3', name: 'Other', businessId: 'biz-2');
      await insert(id: 'c4', name: 'Deleted');
      await db.customersDao.softDelete('c4');

      final rows = await db.customersDao.watchActiveByBusinessId('biz-1').first;
      expect(rows.map((r) => r.name), ['Ana', 'Zoe']);
    });
  });

  group('softDelete', () {
    test('marks deleted + queues a pendingUpdate push (never hard-delete)',
        () async {
      await insert(id: 'c1', syncStatus: SyncStatus.synced);
      await db.customersDao.softDelete('c1');

      final row = await db.customersDao.getById('c1');
      expect(row, isNotNull);
      expect(row!.isDeleted, isTrue);
      expect(row.deletedAt, isNotNull);
      expect(row.syncStatus, SyncStatus.pendingUpdate.toInt());
    });
  });

  group('getPendingSync', () {
    test('returns rows queued for upload/update/failed, not synced', () async {
      await insert(id: 'up', syncStatus: SyncStatus.pendingUpload);
      await insert(id: 'ok', syncStatus: SyncStatus.synced);
      await insert(id: 'fail', syncStatus: SyncStatus.failed);

      final pending = await db.customersDao.getPendingSync();
      expect(pending.map((r) => r.id).toSet(), {'up', 'fail'});
    });
  });

  group('upsertFromServer', () {
    test('inserts a server row marked synced', () async {
      await db.customersDao.upsertFromServer({
        'id': 'srv-1',
        'business_id': 'biz-1',
        'name': 'Server Cust',
        'phone': '0917',
        'is_active': true,
        'is_deleted': false,
        'created_at': DateTime(2026, 6, 1).toIso8601String(),
      });

      final row = await db.customersDao.getById('srv-1');
      expect(row, isNotNull);
      expect(row!.name, 'Server Cust');
      expect(row.phone, '0917');
      expect(row.syncStatus, SyncStatus.synced.toInt());
    });
  });
}
