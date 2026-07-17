import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/fraud_flags_dao.dart';
import 'package:pos/core/sync/sync_status.dart';

void main() {
  late AppDatabase db;
  late FraudFlagsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = FraudFlagsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedFlag(
    String id, {
    int syncStatus = 3, // synced
    String status = 'new',
  }) {
    return db.into(db.fraudFlagsTable).insert(
          FraudFlagsTableCompanion.insert(
            id: id,
            businessId: 'biz1',
            branchId: const Value('br1'),
            ruleCode: 'HIGH_DISCOUNT',
            severity: 'high',
            status: Value(status),
            title: 't',
            description: 'd',
            detectedAt: DateTime(2026, 7, 1),
            dedupeKey: 'HIGH_DISCOUNT|$id',
            syncStatus: Value(syncStatus),
          ),
        );
  }

  Future<FraudFlagRow> flag(String id) =>
      (db.select(db.fraudFlagsTable)..where((t) => t.id.equals(id)))
          .getSingle();

  Map<String, dynamic> serverRow(String id, {String status = 'new'}) => {
        'id': id,
        'business_id': 'biz1',
        'branch_id': 'br1',
        'rule_code': 'HIGH_DISCOUNT',
        'severity': 'high',
        'status': status,
        'title': 't',
        'description': 'd',
        'subject_user_id': null,
        'evidence': const [],
        'related_ids': const [],
        'resolved_by': null,
        'resolution_note': null,
        'detected_at': '2026-07-01T00:00:00.000Z',
        'created_at': '2026-07-01T00:00:00.000Z',
        'updated_at': '2026-07-01T00:00:00.000Z',
        'deleted_at': null,
        'dedupe_key': 'HIGH_DISCOUNT|$id',
      };

  group('resolve sync-status transition', () {
    test('a synced flag moves to pendingUpdate', () async {
      await seedFlag('f1', syncStatus: SyncStatus.synced.toInt());

      await dao.resolve(
        id: 'f1',
        status: 'resolved',
        resolvedBy: 'owner1',
        resolutionNote: 'checked',
      );

      final row = await flag('f1');
      expect(row.status, 'resolved');
      expect(row.resolvedBy, 'owner1');
      expect(row.resolutionNote, 'checked');
      expect(row.syncStatus, SyncStatus.pendingUpdate.toInt());
    });

    test('a never-uploaded (pendingUpload) flag keeps its INSERT path',
        () async {
      await seedFlag('f1', syncStatus: SyncStatus.pendingUpload.toInt());

      await dao.resolve(id: 'f1', status: 'dismissed', resolvedBy: 'owner1');

      final row = await flag('f1');
      expect(row.status, 'dismissed');
      // pendingUpdate here would turn the first upload into a 0-row UPDATE
      // and the flag would silently never reach the server.
      expect(row.syncStatus, SyncStatus.pendingUpload.toInt());
    });

    test('a failed flag retries as a full upload carrying the triage',
        () async {
      await seedFlag('f1', syncStatus: SyncStatus.failed.toInt());

      await dao.resolve(id: 'f1', status: 'resolved', resolvedBy: 'owner1');

      final row = await flag('f1');
      expect(row.syncStatus, SyncStatus.pendingUpload.toInt());
    });

    test('a pendingUpdate flag stays on the UPDATE path', () async {
      await seedFlag('f1', syncStatus: SyncStatus.pendingUpdate.toInt());

      await dao.resolve(id: 'f1', status: 'false_positive', resolvedBy: 'o');

      final row = await flag('f1');
      expect(row.syncStatus, SyncStatus.pendingUpdate.toInt());
    });
  });

  group('upsertFromServer pull guard', () {
    test('applies a new server row and marks it synced', () async {
      final applied = await dao.upsertFromServer(serverRow('f1'));

      expect(applied, isTrue);
      final row = await flag('f1');
      expect(row.status, 'new');
      expect(row.syncStatus, SyncStatus.synced.toInt());
    });

    test('overwrites a synced local row with server state', () async {
      await seedFlag('f1', syncStatus: SyncStatus.synced.toInt());

      final applied =
          await dao.upsertFromServer(serverRow('f1', status: 'resolved'));

      expect(applied, isTrue);
      expect((await flag('f1')).status, 'resolved');
    });

    test('keeps local triage that has not pushed yet (pendingUpdate)',
        () async {
      await seedFlag('f1', syncStatus: SyncStatus.synced.toInt());
      await dao.resolve(id: 'f1', status: 'resolved', resolvedBy: 'owner1');

      // Server still has the pre-triage state; the pull must not revert.
      final applied = await dao.upsertFromServer(serverRow('f1'));

      expect(applied, isFalse);
      final row = await flag('f1');
      expect(row.status, 'resolved');
      expect(row.syncStatus, SyncStatus.pendingUpdate.toInt());
    });

    test('keeps a locally-detected flag that has not uploaded yet', () async {
      await seedFlag('f1', syncStatus: SyncStatus.pendingUpload.toInt());

      final applied = await dao.upsertFromServer(serverRow('f1'));

      expect(applied, isFalse);
      expect((await flag('f1')).syncStatus, SyncStatus.pendingUpload.toInt());
    });

    test('keeps a failed row so its retry is not erased', () async {
      await seedFlag('f1', syncStatus: SyncStatus.failed.toInt());

      final applied = await dao.upsertFromServer(serverRow('f1'));

      expect(applied, isFalse);
      expect((await flag('f1')).syncStatus, SyncStatus.failed.toInt());
    });
  });
}
