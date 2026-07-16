import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/audit/audit_mirror_repair.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/device/device_identity_service.dart';
import 'package:pos/core/sync/sync_status.dart';

class MockDeviceIdentityService extends Mock implements DeviceIdentityService {}

void main() {
  late AppDatabase db;
  late AuditLogsDao dao;
  final now = DateTime.now();

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = AuditLogsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  int unix(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  Future<void> seedChained({
    required String id,
    required String deviceUid,
    required int seq,
    DateTime? at,
    int syncStatus = 3, // synced
  }) {
    return db.customStatement(
      'INSERT INTO audit_logs (id, business_id, branch_id, user_id, '
      'action_type, entity_type, description, metadata, device_id, '
      'created_at, seq, device_uid, sync_status) '
      "VALUES (?, 'biz1', 'br1', 'u1', 'SALE_CREATED', 'test', 'x', '{}', "
      "'D', ?, ?, ?, ?)",
      [id, unix(at ?? now), seq, deviceUid, syncStatus],
    );
  }

  /// Server-shaped row for the fetcher fake (what upsertFromServer expects).
  Map<String, dynamic> serverRow(String deviceUid, int seq) => {
        'id': 'srv-$deviceUid-$seq',
        'business_id': 'biz1',
        'branch_id': 'br1',
        'user_id': 'u1',
        'action_type': 'SALE_CREATED',
        'entity_type': 'test',
        'entity_id': null,
        'description': 'x',
        'metadata': const <String, dynamic>{},
        'device_id': 'D',
        'created_at': now.toUtc().toIso8601String(),
        'seq': seq,
        'previous_hash': 'p$seq',
        'hash': 'h$seq',
        'device_uid': deviceUid,
        'hash_version': 2,
      };

  group('gap detection (getChainGaps)', () {
    test('reports each hole inside a retained chain, never the edges',
        () async {
      for (final seq in [1, 2, 5, 6, 9]) {
        await seedChained(id: 'a$seq', deviceUid: 'dev2', seq: seq);
      }
      final gaps = await dao.getChainGaps('biz1');
      expect(gaps, hasLength(2));
      expect(gaps[0], (deviceUid: 'dev2', fromSeq: 3, toSeq: 4));
      expect(gaps[1], (deviceUid: 'dev2', fromSeq: 7, toSeq: 8));
    });

    test('a contiguous chain has no gaps', () async {
      for (final seq in [4, 5, 6]) {
        await seedChained(id: 'a$seq', deviceUid: 'dev2', seq: seq);
      }
      expect(await dao.getChainGaps('biz1'), isEmpty);
    });
  });

  group('AuditMirrorRepair', () {
    AuditMirrorRepair build({
      required Map<String, List<Map<String, dynamic>>> serverChains,
      List<Map<String, dynamic>>? heads,
      List<({String uid, int from, int to})>? calls,
    }) {
      final identity = MockDeviceIdentityService();
      when(identity.getDeviceUid).thenAnswer((_) async => 'dev1');
      return AuditMirrorRepair(
        dao: dao,
        deviceIdentityService: identity,
        fetchChainHeads: heads == null ? null : () async => heads,
        fetchChainRows: (businessId, deviceUid,
            {required fromSeq, required toSeq, limit = 500}) async {
          calls?.add((uid: deviceUid, from: fromSeq, to: toSeq));
          return (serverChains[deviceUid] ?? const [])
              .where((r) =>
                  (r['seq'] as int) >= fromSeq && (r['seq'] as int) <= toSeq)
              .take(limit)
              .toList();
        },
      );
    }

    test('refetches a mid-chain hole so it stops reading as a seqGap',
        () async {
      // The 2026-07-03 recurrence vector: rows pushed late land BEHIND the
      // created_at watermark and are never pulled — seqs 3–4 are missing.
      for (final seq in [1, 2, 5]) {
        await seedChained(id: 'a$seq', deviceUid: 'dev2', seq: seq);
      }
      final repair = build(serverChains: {
        'dev2': [serverRow('dev2', 3), serverRow('dev2', 4)],
      });

      final repaired = await repair.repair('biz1');

      expect(repaired, 2);
      expect(await dao.getChainGaps('biz1'), isEmpty);
    });

    test('a hole the server also lacks stays missing (true detection)',
        () async {
      for (final seq in [1, 2, 5]) {
        await seedChained(id: 'a$seq', deviceUid: 'dev2', seq: seq);
      }
      final repair = build(serverChains: {'dev2': const []});

      expect(await repair.repair('biz1'), 0);
      expect(await dao.getChainGaps('biz1'), hasLength(1));
    });

    test("extends another device's stale tail up to the server head",
        () async {
      for (final seq in [1, 2]) {
        await seedChained(id: 'a$seq', deviceUid: 'dev2', seq: seq);
      }
      final repair = build(
        serverChains: {
          'dev2': [serverRow('dev2', 3), serverRow('dev2', 4)],
        },
        heads: [
          {'device_uid': 'dev2', 'max_seq': 4},
        ],
      );

      expect(await repair.repair('biz1'), 2);
      final heads = await dao.getLocalChainHeads('biz1');
      expect(heads['dev2'], 4);
    });

    test("never touches the OWN device's tail — the writer owns those seqs",
        () async {
      await seedChained(id: 'a1', deviceUid: 'dev1', seq: 1);
      final calls = <({String uid, int from, int to})>[];
      final repair = build(
        serverChains: {
          'dev1': [serverRow('dev1', 2), serverRow('dev1', 3)],
        },
        heads: [
          {'device_uid': 'dev1', 'max_seq': 3},
        ],
        calls: calls,
      );

      expect(await repair.repair('biz1'), 0);
      expect(calls, isEmpty);
    });

    test('a chain with no local rows is not backfilled', () async {
      final calls = <({String uid, int from, int to})>[];
      final repair = build(
        serverChains: {
          'dev3': [serverRow('dev3', 1)],
        },
        heads: [
          {'device_uid': 'dev3', 'max_seq': 1},
        ],
        calls: calls,
      );

      expect(await repair.repair('biz1'), 0);
      expect(calls, isEmpty);
    });
  });

  group('chain-safe prune', () {
    final cutoff = now.subtract(const Duration(days: 90));
    final old = now.subtract(const Duration(days: 100));

    Future<Set<int>> retainedSeqs(String uid) async {
      final rows = await dao.getChainedRows('biz1');
      return {
        for (final r in rows)
          if (r.deviceUid == uid) r.seq!,
      };
    }

    test('a re-chained block with old timestamps mid-chain is NOT deleted',
        () async {
      // Seqs 1–2 newer than the cutoff, seqs 3–4 OLDER (a transplanted tail
      // keeps original timestamps under new seqs). A naive created_at prune
      // would delete 3–4 mid-chain → seqGap → critical false tamper flag.
      await seedChained(id: 'a1', deviceUid: 'dev1', seq: 1);
      await seedChained(id: 'a2', deviceUid: 'dev1', seq: 2);
      await seedChained(id: 'a3', deviceUid: 'dev1', seq: 3, at: old);
      await seedChained(id: 'a4', deviceUid: 'dev1', seq: 4, at: old);

      await dao.pruneOlderThan(cutoff);

      expect(await retainedSeqs('dev1'), {1, 2, 3, 4});
    });

    test('an old stuck unsynced row holds back its whole prefix', () async {
      // All rows old; seq 3 never synced. Deleting its synced neighbors
      // would leave 3 alone → retained chain no longer contiguous.
      for (final seq in [1, 2, 4, 5]) {
        await seedChained(id: 'a$seq', deviceUid: 'dev1', seq: seq, at: old);
      }
      await seedChained(
        id: 'a3',
        deviceUid: 'dev1',
        seq: 3,
        at: old,
        syncStatus: SyncStatus.failed.toInt(),
      );

      await dao.pruneOlderThan(cutoff);

      expect(await retainedSeqs('dev1'), {3, 4, 5});
    });

    test('a fully old, fully synced chain is pruned away', () async {
      for (final seq in [1, 2, 3]) {
        await seedChained(id: 'a$seq', deviceUid: 'dev1', seq: seq, at: old);
      }
      await dao.pruneOlderThan(cutoff);
      expect(await retainedSeqs('dev1'), isEmpty);
    });

    test('the normal case still prunes the old prefix', () async {
      await seedChained(id: 'a1', deviceUid: 'dev1', seq: 1, at: old);
      await seedChained(id: 'a2', deviceUid: 'dev1', seq: 2, at: old);
      await seedChained(id: 'a3', deviceUid: 'dev1', seq: 3);

      await dao.pruneOlderThan(cutoff);

      expect(await retainedSeqs('dev1'), {3});
    });

    test('non-chained rows keep the plain age rule', () async {
      await db.customStatement(
        'INSERT INTO audit_logs (id, business_id, branch_id, user_id, '
        'action_type, entity_type, description, metadata, device_id, '
        'created_at, sync_status) '
        "VALUES ('n1', 'biz1', 'br1', 'u1', 'X', 't', 'x', '{}', 'D', ?, 3)",
        [unix(old)],
      );
      await db.customStatement(
        'INSERT INTO audit_logs (id, business_id, branch_id, user_id, '
        'action_type, entity_type, description, metadata, device_id, '
        'created_at, sync_status) '
        "VALUES ('n2', 'biz1', 'br1', 'u1', 'X', 't', 'x', '{}', 'D', ?, 0)",
        [unix(old)],
      );

      await dao.pruneOlderThan(cutoff);

      final rows = await dao.getByBusiness('biz1');
      expect(rows.map((r) => r.id), ['n2']); // unsynced survives, synced goes
    });
  });
}
