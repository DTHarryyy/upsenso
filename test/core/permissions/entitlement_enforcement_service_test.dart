import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/permissions/data/entitlement_remote_ds.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/session/active_business_context.dart';

class MockEntitlementRemoteDs extends Mock implements EntitlementRemoteDs {}

/// The over-cap policy: buying one month of Growth, creating five branches and
/// twelve staff logins, then cancelling must not keep all of it forever.
void main() {
  late AppDatabase db;
  late ActiveBusinessContext ctx;
  late EmployeesDao empDao;
  late BranchesDao branchDao;
  late EntitlementService entitlement;
  late EntitlementEnforcementService enforcement;

  const biz = 'biz-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ctx = ActiveBusinessContext()..set(userId: 'u1', businessId: biz);
    empDao = EmployeesDao(db);
    branchDao = BranchesDao(db);
    entitlement = EntitlementService(
      entitlementDao: db.entitlementDao,
      entitlementRemoteDs: MockEntitlementRemoteDs(),
      activeBusinessContext: ctx,
      employeesDao: empDao,
      branchesDao: branchDao,
    );
    enforcement = EntitlementEnforcementService(
      entitlementDao: db.entitlementDao,
      entitlementService: entitlement,
      branchesDao: branchDao,
      employeesDao: empDao,
      activeBusinessContext: ctx,
    );
  });

  tearDown(() async {
    enforcement.dispose();
    await db.close();
  });

  /// Branches created oldest-first so `localUpdatedAt` ordering is deterministic.
  Future<void> addBranches(int n) async {
    for (var i = 0; i < n; i++) {
      await db.into(db.branchesTable).insert(
            BranchesTableCompanion.insert(
              id: 'br-$i',
              businessId: biz,
              name: 'Branch $i',
              localUpdatedAt: Value(DateTime(2026, 1, i + 1)),
            ),
          );
    }
  }

  Future<void> addEmployees(int n, {String? ownerAt}) async {
    for (var i = 0; i < n; i++) {
      await empDao.insertEmployee(
        EmployeesTableCompanion.insert(
          id: 'emp-$i',
          businessId: biz,
          roleName: Value(ownerAt == 'emp-$i' ? 'business_owner' : 'cashier'),
          createdAt: Value(DateTime(2026, 1, i + 1)),
          isActive: const Value(true),
        ),
      );
    }
  }

  Future<void> setPlan({int? maxBranches, int? maxSeats}) async {
    await db.entitlementDao.saveEntitlement(EntitlementCacheTableCompanion(
      businessId: const Value(biz),
      planCode: const Value('free'),
      status: const Value('free'),
      featureFlagsJson: Value(json.encode(const {})),
      maxBranches: Value(maxBranches),
      maxSeats: Value(maxSeats),
    ));
    await entitlement.loadFromCache();
  }

  group('branches', () {
    test('nothing is locked while the tenant is inside the cap', () async {
      await addBranches(3);
      await setPlan(maxBranches: 5);
      await enforcement.reconcile();

      expect(enforcement.lockedBranchIds, isEmpty);
      expect(enforcement.hasOverCapResources, isFalse);
    });

    test('5 branches on a 1-branch plan locks 4 and keeps the oldest', () async {
      await addBranches(5);
      await setPlan(maxBranches: 1);
      await enforcement.reconcile();

      expect(enforcement.lockedBranchIds, hasLength(4));
      expect(enforcement.isBranchLocked('br-0'), isFalse); // oldest survives
      expect(enforcement.isBranchLocked('br-4'), isTrue);
      expect(enforcement.hasOverCapResources, isTrue);
    });

    test('the branch currently open in POS is never the one locked', () async {
      await addBranches(5);
      await setPlan(maxBranches: 1);
      // Standing at the newest branch — the one oldest-first would have locked.
      enforcement.noteActiveBranch('br-4');
      await enforcement.reconcile();

      expect(enforcement.isBranchLocked('br-4'), isFalse);
      expect(enforcement.lockedBranchIds, hasLength(4));
    });

    test('an unlimited cap locks nothing', () async {
      await addBranches(9);
      await setPlan(maxBranches: null);
      await enforcement.reconcile();

      expect(enforcement.lockedBranchIds, isEmpty);
    });

    test('upgrading releases every lock with no manual cleanup', () async {
      await addBranches(5);
      await setPlan(maxBranches: 1);
      await enforcement.reconcile();
      expect(enforcement.lockedBranchIds, hasLength(4));

      await setPlan(maxBranches: 5); // they paid again
      await enforcement.reconcile();
      expect(enforcement.lockedBranchIds, isEmpty);
    });

    test('reconcile is idempotent', () async {
      await addBranches(4);
      await setPlan(maxBranches: 2);
      await enforcement.reconcile();
      final first = {...enforcement.lockedBranchIds};
      await enforcement.reconcile();

      expect(enforcement.lockedBranchIds, first);
    });

    test('locks survive a restart via the Drift table', () async {
      await addBranches(3);
      await setPlan(maxBranches: 1);
      await enforcement.reconcile();
      final expected = {...enforcement.lockedBranchIds};

      final fresh = EntitlementEnforcementService(
        entitlementDao: db.entitlementDao,
        entitlementService: entitlement,
        branchesDao: branchDao,
        employeesDao: empDao,
        activeBusinessContext: ctx,
      );
      await fresh.load();
      expect(fresh.lockedBranchIds, expected);
      fresh.dispose();
    });

    test('the owner can re-pick which branch stays active', () async {
      await addBranches(3);
      await setPlan(maxBranches: 1);
      await enforcement.reconcile();
      expect(enforcement.isBranchLocked('br-0'), isFalse);

      final ok = await enforcement.chooseActiveBranches({'br-2'});
      expect(ok, isTrue);
      expect(enforcement.isBranchLocked('br-2'), isFalse);
      expect(enforcement.isBranchLocked('br-0'), isTrue);
    });

    test('a choice that exceeds the cap is refused outright', () async {
      await addBranches(3);
      await setPlan(maxBranches: 1);
      await enforcement.reconcile();

      final ok = await enforcement.chooseActiveBranches({'br-0', 'br-1'});
      expect(ok, isFalse);
    });
  });

  group('assertBranchWritable', () {
    test('throws for a locked branch and passes for an active one', () async {
      await addBranches(2);
      await setPlan(maxBranches: 1);
      await enforcement.reconcile();

      expect(
        () => enforcement.assertBranchWritable('br-1'),
        throwsA(isA<BranchLockedException>()),
      );
      expect(() => enforcement.assertBranchWritable('br-0'), returnsNormally);
    });

    test('a null branch is the All-Branches view, not a lock', () {
      expect(() => enforcement.assertBranchWritable(null), returnsNormally);
    });
  });

  group('seats', () {
    test('12 staff on a 2-seat plan suspends 10 and keeps the owner', () async {
      await addEmployees(12, ownerAt: 'emp-5');
      await setPlan(maxSeats: 2);
      await enforcement.reconcile();

      expect(enforcement.suspendedEmployeeIds, hasLength(10));
      // The owner pays the bill — locking them out would be absurd.
      expect(enforcement.isEmployeeSuspended('emp-5'), isFalse);
      // Then oldest-first for the remaining seat.
      expect(enforcement.isEmployeeSuspended('emp-0'), isFalse);
      expect(enforcement.isEmployeeSuspended('emp-11'), isTrue);
    });

    test('already-inactive staff consume no seat and need no suspension',
        () async {
      await addEmployees(4, ownerAt: 'emp-0');
      await empDao.updateEmployee(
        'emp-3',
        const EmployeesTableCompanion(isActive: Value(false)),
      );
      await setPlan(maxSeats: 3);
      await enforcement.reconcile();

      expect(enforcement.suspendedEmployeeIds, isEmpty);
    });

    test('upgrading restores everyone', () async {
      await addEmployees(6, ownerAt: 'emp-0');
      await setPlan(maxSeats: 2);
      await enforcement.reconcile();
      expect(enforcement.suspendedEmployeeIds, hasLength(4));

      await setPlan(maxSeats: 15);
      await enforcement.reconcile();
      expect(enforcement.suspendedEmployeeIds, isEmpty);
    });

    test('the owner is kept even when left out of an explicit choice', () async {
      await addEmployees(4, ownerAt: 'emp-0');
      await setPlan(maxSeats: 2);
      await enforcement.reconcile();

      final ok = await enforcement.chooseActiveSeats({'emp-3'});
      expect(ok, isTrue);
      expect(enforcement.isEmployeeSuspended('emp-0'), isFalse);
      expect(enforcement.isEmployeeSuspended('emp-3'), isFalse);
      expect(enforcement.isEmployeeSuspended('emp-1'), isTrue);
    });
  });

  test('clear() drops in-memory state without touching the rows', () async {
    await addBranches(3);
    await setPlan(maxBranches: 1);
    await enforcement.reconcile();
    expect(enforcement.hasOverCapResources, isTrue);

    await enforcement.clear();
    expect(enforcement.lockedBranchIds, isEmpty);
    expect(enforcement.hasOverCapResources, isFalse);
  });
}
