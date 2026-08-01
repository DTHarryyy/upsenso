import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/sync/sync_status.dart';

void main() {
  late AppDatabase db;
  late BranchesDao dao;
  const biz = 'biz-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = BranchesDao(db);
  });

  tearDown(() => db.close());

  Future<void> insert(String id, {SyncStatus? status}) {
    return db.into(db.branchesTable).insert(
          BranchesTableCompanion.insert(
            id: id,
            businessId: biz,
            name: id,
            syncStatus: Value((status ?? SyncStatus.synced).toInt()),
          ),
        );
  }

  group('countForBusiness — the number behind the branch cap', () {
    test('counts live branches for this business only', () async {
      await insert('a');
      await insert('b');
      await db.into(db.branchesTable).insert(
            BranchesTableCompanion.insert(
              id: 'other',
              businessId: 'biz-2',
              name: 'Other',
            ),
          );

      expect(await dao.countForBusiness(biz), 2);
    });

    // Counting pending-delete rows kept a tenant pinned at their cap until the
    // delete synced — offline, that meant forever: delete a branch, still can't
    // create its replacement. Mirrors EmployeesDao.countActiveForBusiness.
    test('a branch queued for deletion frees its slot immediately', () async {
      await insert('a');
      await insert('b');
      expect(await dao.countForBusiness(biz), 2);

      await dao.markForDeletion('b');
      expect(await dao.countForBusiness(biz), 1);
    });

    test('pending upload and update rows still count', () async {
      await insert('a', status: SyncStatus.pendingUpload);
      await insert('b', status: SyncStatus.pendingUpdate);
      await insert('c', status: SyncStatus.failed);

      expect(await dao.countForBusiness(biz), 3);
    });

    test('no branches counts zero rather than throwing', () async {
      expect(await dao.countForBusiness(biz), 0);
    });
  });
}
