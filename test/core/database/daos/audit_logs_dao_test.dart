import 'package:drift/drift.dart';
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

  Future<void> insertRow({
    required String id,
    required DateTime createdAt,
    required SyncStatus syncStatus,
  }) {
    return db.auditLogsDao.insert(
      AuditLogsTableCompanion.insert(
        id: id,
        businessId: 'biz-1',
        branchId: 'branch-1',
        userId: 'user-1',
        actionType: 'SALE_CREATED',
        entityType: 'transaction',
        description: 'test row',
        createdAt: Value(createdAt),
        syncStatus: Value(syncStatus.toInt()),
      ),
    );
  }

  group('pruneOlderThan', () {
    test('deletes synced rows older than the cutoff', () async {
      final cutoff = DateTime(2026, 1, 1);
      await insertRow(
        id: 'old-synced',
        createdAt: DateTime(2025, 12, 1),
        syncStatus: SyncStatus.synced,
      );

      await db.auditLogsDao.pruneOlderThan(cutoff);

      final remaining = await db.auditLogsDao.getByBusiness('biz-1');
      expect(remaining, isEmpty);
    });

    test('keeps synced rows at or after the cutoff', () async {
      final cutoff = DateTime(2026, 1, 1);
      await insertRow(
        id: 'recent-synced',
        createdAt: DateTime(2026, 2, 1),
        syncStatus: SyncStatus.synced,
      );

      await db.auditLogsDao.pruneOlderThan(cutoff);

      final remaining = await db.auditLogsDao.getByBusiness('biz-1');
      expect(remaining.map((r) => r.id), ['recent-synced']);
    });

    test(
      'never deletes a pending row regardless of age — server may not have it yet',
      () async {
        final cutoff = DateTime(2026, 1, 1);
        await insertRow(
          id: 'old-pending',
          createdAt: DateTime(2020, 1, 1),
          syncStatus: SyncStatus.pendingUpload,
        );

        await db.auditLogsDao.pruneOlderThan(cutoff);

        final remaining = await db.auditLogsDao.getByBusiness('biz-1');
        expect(remaining.map((r) => r.id), ['old-pending']);
      },
    );

    test('never deletes a failed row regardless of age', () async {
      final cutoff = DateTime(2026, 1, 1);
      await insertRow(
        id: 'old-failed',
        createdAt: DateTime(2020, 1, 1),
        syncStatus: SyncStatus.failed,
      );

      await db.auditLogsDao.pruneOlderThan(cutoff);

      final remaining = await db.auditLogsDao.getByBusiness('biz-1');
      expect(remaining.map((r) => r.id), ['old-failed']);
    });
  });
}
