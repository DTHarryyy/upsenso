import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/sync/sync_status.dart';

// Stage 3 proof-of-pattern (suppliers): tombstone propagation + pending-wins
// guard on the pull path. These are the two correctness properties the delta
// conversion depends on; the delta paging itself is exercised by _pullIncremental
// + a live round-trip.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insertLocal({
    required String id,
    String businessId = 'biz-1',
    String name = 'Acme',
    SyncStatus syncStatus = SyncStatus.pendingUpload,
  }) {
    return db.suppliersDao.insert(
      SuppliersTableCompanion.insert(
        id: id,
        businessId: businessId,
        name: name,
        syncStatus: Value(syncStatus.toInt()),
      ),
    );
  }

  Map<String, dynamic> serverRow({
    required String id,
    String name = 'Server Co',
    bool isDeleted = false,
  }) => {
    'id': id,
    'business_id': 'biz-1',
    'name': name,
    'is_active': true,
    'is_deleted': isDeleted,
    'deleted_at': isDeleted ? DateTime(2026, 7, 1).toIso8601String() : null,
    'created_at': DateTime(2026, 6, 1).toIso8601String(),
    'updated_at': DateTime(2026, 7, 1).toIso8601String(),
  };

  group('upsertFromServer', () {
    test('inserts a server row marked synced', () async {
      await db.suppliersDao.upsertFromServer(serverRow(id: 's1'));

      final row = await db.suppliersDao.getById('s1');
      expect(row, isNotNull);
      expect(row!.name, 'Server Co');
      expect(row.syncStatus, SyncStatus.synced.toInt());
    });

    test('propagates a soft-delete tombstone — is_deleted hides the row',
        () async {
      await insertLocal(id: 's1', name: 'Acme', syncStatus: SyncStatus.synced);

      // Another device deleted it; the tombstone arrives via delta pull.
      await db.suppliersDao
          .upsertFromServer(serverRow(id: 's1', name: 'Acme', isDeleted: true));

      final row = await db.suppliersDao.getById('s1');
      expect(row!.isDeleted, isTrue);
      final active = await db.suppliersDao.getActiveByBusinessId('biz-1');
      expect(active.where((r) => r.id == 's1'), isEmpty);
    });

    test('does NOT overwrite a local row with unsynced changes (pending wins)',
        () async {
      await insertLocal(
        id: 's1',
        name: 'Local Edit',
        syncStatus: SyncStatus.pendingUpdate,
      );

      // A stale/concurrent server version arrives during the same pull.
      await db.suppliersDao
          .upsertFromServer(serverRow(id: 's1', name: 'Server Version'));

      final row = await db.suppliersDao.getById('s1');
      expect(row!.name, 'Local Edit');
      expect(row.syncStatus, SyncStatus.pendingUpdate.toInt());
    });

    test('overwrites a local row that is already synced', () async {
      await insertLocal(id: 's1', name: 'Old', syncStatus: SyncStatus.synced);

      await db.suppliersDao.upsertFromServer(serverRow(id: 's1', name: 'New'));

      final row = await db.suppliersDao.getById('s1');
      expect(row!.name, 'New');
      expect(row.syncStatus, SyncStatus.synced.toInt());
    });
  });
}
