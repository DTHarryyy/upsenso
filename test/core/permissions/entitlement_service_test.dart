import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/data/entitlement_remote_ds.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/session/active_business_context.dart';

class MockEntitlementRemoteDs extends Mock implements EntitlementRemoteDs {}

void main() {
  late AppDatabase db;
  late MockEntitlementRemoteDs remoteDs;
  late ActiveBusinessContext ctx;
  late EmployeesDao empDao;
  late BranchesDao branchDao;
  late EntitlementService service;

  const biz = 'biz-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remoteDs = MockEntitlementRemoteDs();
    ctx = ActiveBusinessContext()..set(userId: 'u1', businessId: biz);
    empDao = EmployeesDao(db);
    branchDao = BranchesDao(db);
    service = EntitlementService(
      entitlementDao: db.entitlementDao,
      entitlementRemoteDs: remoteDs,
      activeBusinessContext: ctx,
      employeesDao: empDao,
      branchesDao: branchDao,
    );
  });

  Future<void> addActiveEmployees(int n) async {
    for (var i = 0; i < n; i++) {
      await empDao.insertEmployee(
        EmployeesTableCompanion.insert(id: 'emp-$i', businessId: biz),
      );
    }
  }

  Future<void> addBranches(int n) async {
    for (var i = 0; i < n; i++) {
      await db.into(db.branchesTable).insert(
            BranchesTableCompanion.insert(
                id: 'br-$i', businessId: biz, name: 'B$i'),
          );
    }
  }

  tearDown(() => db.close());

  Future<void> seed({
    required String status,
    bool cloudEnabled = true,
    Map<String, dynamic> flags = const {},
    DateTime? trialEnd,
    DateTime? currentPeriodEnd,
    DateTime? graceUntil,
    DateTime? lastServerSyncAt,
    String? billingPeriod,
    int? maxBranches = 3,
    int? maxSeats = 10,
    int? maxDevices = 5,
  }) async {
    await db.entitlementDao.saveEntitlement(EntitlementCacheTableCompanion(
      businessId: const Value(biz),
      planCode: Value(cloudEnabled ? 'growth' : 'free'),
      status: Value(status),
      billingPeriod: Value(billingPeriod),
      cloudEnabled: Value(cloudEnabled),
      featureFlagsJson: Value(json.encode(flags)),
      maxBranches: Value(maxBranches),
      maxSeats: Value(maxSeats),
      maxDevices: Value(maxDevices),
      trialEnd: Value(trialEnd),
      currentPeriodEnd: Value(currentPeriodEnd),
      graceUntil: Value(graceUntil),
      lastServerSyncAt: Value(lastServerSyncAt),
    ));
    await service.loadFromCache();
  }

  final now = DateTime.now();

  group('effectiveStatus', () {
    test('active when the paid period is still running', () async {
      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)));
      expect(service.effectiveStatus, 'active');
      expect(service.cloudEnabled, isTrue);
    });

    test('trialing inside the trial window with no paid period', () async {
      await seed(status: 'trialing', trialEnd: now.add(const Duration(days: 5)));
      expect(service.effectiveStatus, 'trialing');
      expect(service.cloudEnabled, isTrue);
    });

    test('past_due when period ended but still inside grace', () async {
      await seed(
        status: 'active',
        currentPeriodEnd: now.subtract(const Duration(days: 1)),
        graceUntil: now.add(const Duration(days: 5)),
      );
      expect(service.effectiveStatus, 'past_due');
      expect(service.cloudEnabled, isTrue); // POS + cloud stay on through grace
    });

    test('lapsed when period AND grace are both past', () async {
      await seed(
        status: 'active',
        currentPeriodEnd: now.subtract(const Duration(days: 30)),
        graceUntil: now.subtract(const Duration(days: 5)),
      );
      expect(service.effectiveStatus, 'lapsed');
      expect(service.cloudEnabled, isFalse); // reverts to local — sync gate closes
    });

    test('free when there is no cache row at all', () async {
      // no seed()
      expect(service.effectiveStatus, 'free');
      expect(service.cloudEnabled, isFalse);
    });
  });

  group('clock-tamper clamp (§7.4)', () {
    test('a future server-sync anchor cannot be undone by rolling the clock back',
        () async {
      // Period/grace both end soon by real time, but the last server contact is
      // 10 days AHEAD — so effective "now" is clamped forward and the plan reads
      // as lapsed. Rolling the device clock back can never regain grace.
      await seed(
        status: 'active',
        currentPeriodEnd: now.add(const Duration(days: 1)),
        graceUntil: now.add(const Duration(days: 1)),
        lastServerSyncAt: now.add(const Duration(days: 10)),
      );
      expect(service.effectiveStatus, 'lapsed');
      expect(service.cloudEnabled, isFalse);
    });
  });

  // Play renews silently; the client only learns about it via
  // get_my_entitlement(). Without this window a paying merchant who is offline
  // over their renewal date gets downgraded despite having been charged.
  group('offline verification window (§7.4)', () {
    test('period ended with no server contact keeps the plan alive', () async {
      await seed(
        status: 'active',
        currentPeriodEnd: now.subtract(const Duration(days: 2)),
        lastServerSyncAt: now.subtract(const Duration(days: 3)),
      );
      expect(service.effectiveStatus, 'unverified');
      // Cloud stays ON: they most likely paid, and cutting backup off is the
      // one failure mode that loses real data.
      expect(service.cloudEnabled, isTrue);
      expect(service.verificationDaysLeft, greaterThan(0));
    });

    test('degrades to lapsed once the 14-day window closes', () async {
      await seed(
        status: 'active',
        currentPeriodEnd: now.subtract(const Duration(days: 20)),
        lastServerSyncAt: now.subtract(const Duration(days: 15)),
      );
      expect(service.effectiveStatus, 'lapsed');
      expect(service.cloudEnabled, isFalse);
      expect(service.verificationDaysLeft, isNull);
    });

    test('annual gets 30 days, so day 20 is still covered', () async {
      await seed(
        status: 'active',
        billingPeriod: 'annual',
        currentPeriodEnd: now.subtract(const Duration(days: 19)),
        lastServerSyncAt: now.subtract(const Duration(days: 20)),
      );
      expect(service.effectiveStatus, 'unverified');

      // ...and the same 20 days on monthly has already expired.
      await seed(
        status: 'active',
        billingPeriod: 'monthly',
        currentPeriodEnd: now.subtract(const Duration(days: 19)),
        lastServerSyncAt: now.subtract(const Duration(days: 20)),
      );
      expect(service.effectiveStatus, 'lapsed');
    });

    test('no window once the server itself has confirmed the lapse', () async {
      // We DID reach the server after the period ended and it still said over.
      // That's knowledge, not silence — nothing left to verify.
      await seed(
        status: 'active',
        currentPeriodEnd: now.subtract(const Duration(days: 10)),
        lastServerSyncAt: now.subtract(const Duration(days: 1)),
      );
      expect(service.effectiveStatus, 'lapsed');
    });

    test('a cancelled subscription never gets the benefit of the doubt', () async {
      await seed(
        status: 'canceled',
        currentPeriodEnd: now.subtract(const Duration(days: 1)),
        lastServerSyncAt: now.subtract(const Duration(days: 2)),
      );
      expect(service.effectiveStatus, 'lapsed');
    });

    test('grace still wins over the window while it is running', () async {
      await seed(
        status: 'active',
        currentPeriodEnd: now.subtract(const Duration(days: 1)),
        graceUntil: now.add(const Duration(days: 5)),
        lastServerSyncAt: now.subtract(const Duration(days: 2)),
      );
      expect(service.effectiveStatus, 'past_due');
    });

    test('rolling the clock back cannot reopen a closed window', () async {
      // Anchor is 40 days in the FUTURE relative to the (rewound) device clock;
      // the clamp pulls "now" forward past the window either way.
      await seed(
        status: 'active',
        currentPeriodEnd: now.add(const Duration(days: 1)),
        lastServerSyncAt: now.add(const Duration(days: 40)),
      );
      expect(service.effectiveStatus, 'lapsed');
    });
  });

  group('featureAllowed', () {
    test('CRM directory allowed on basic and full, denied when false', () async {
      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)), flags: {'crm': 'basic'});
      expect(service.featureAllowed(AppFeature.customerDirectory), isTrue);

      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)), flags: {'crm': 'full'});
      expect(service.featureAllowed(AppFeature.customerDirectory), isTrue);
      expect(service.crmFull, isTrue);

      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)), flags: {'crm': false});
      expect(service.featureAllowed(AppFeature.customerDirectory), isFalse);
    });

    test('procurement gated on the procurement flag', () async {
      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)), flags: {'procurement': true});
      expect(service.featureAllowed(AppFeature.procurement), isTrue);
      expect(service.featureAllowed(AppFeature.supplierDirectory), isTrue);

      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)), flags: {'procurement': false});
      expect(service.featureAllowed(AppFeature.procurement), isFalse);
    });

    test('non-premium features are always allowed', () async {
      await seed(status: 'free', cloudEnabled: false, flags: {});
      expect(service.featureAllowed(AppFeature.posTerminal), isTrue);
      expect(service.featureAllowed(AppFeature.inventoryManagement), isTrue);
      expect(service.featureAllowed(AppFeature.expensesModule), isTrue);
    });

    // The two audit surfaces sit on different rungs: `cloud` (Starter) makes
    // the chain browsable, `full` (Growth) adds the Unusual Activity dashboard.
    // Before the split both gated on `full`, so Starter paid for a rung that
    // unlocked nothing.
    test('audit log opens on cloud; unusual activity needs full', () async {
      final live = now.add(const Duration(days: 10));

      // Growth: both surfaces.
      await seed(status: 'active', currentPeriodEnd: live, flags: {'audit': 'full'});
      expect(service.featureAllowed(AppFeature.auditLogs), isTrue);
      expect(service.featureAllowed(AppFeature.fraudAlerts), isTrue);
      expect(service.auditFull, isTrue);
      expect(service.auditCloudBacked, isTrue);

      // Starter: the log is backed up AND readable; the dashboard is not sold.
      await seed(status: 'active', currentPeriodEnd: live, flags: {'audit': 'cloud'});
      expect(service.featureAllowed(AppFeature.auditLogs), isTrue);
      expect(service.featureAllowed(AppFeature.fraudAlerts), isFalse);
      expect(service.auditFull, isFalse);
      expect(service.auditCloudBacked, isTrue);

      // Free: local chain only — neither surface, and the split must not have
      // loosened this.
      await seed(status: 'free', cloudEnabled: false, flags: {'audit': 'local'});
      expect(service.featureAllowed(AppFeature.auditLogs), isFalse);
      expect(service.featureAllowed(AppFeature.fraudAlerts), isFalse);
      expect(service.auditCloudBacked, isFalse);
    });

    test('a missing audit flag falls back to local, never to a paid rung',
        () async {
      await seed(
        status: 'active',
        currentPeriodEnd: now.add(const Duration(days: 10)),
        flags: {},
      );
      expect(service.auditRank, 'local');
      expect(service.featureAllowed(AppFeature.auditLogs), isFalse);
      expect(service.featureAllowed(AppFeature.fraudAlerts), isFalse);
    });

    test('reportsFull tracks the reports flag', () async {
      final live = now.add(const Duration(days: 10));

      await seed(status: 'active', currentPeriodEnd: live, flags: {'reports': 'full'});
      expect(service.reportsFull, isTrue);

      await seed(status: 'active', currentPeriodEnd: live, flags: {'reports': 'basic'});
      expect(service.reportsFull, isFalse);
    });

    test('fail-open with no cache: premium UI is not bricked, but cloud is off',
        () async {
      // no seed() — fresh install offline
      expect(service.featureAllowed(AppFeature.customerDirectory), isTrue);
      expect(service.featureAllowed(AppFeature.procurement), isTrue);
      expect(service.cloudEnabled, isFalse); // cloud fails closed
    });
  });

  group('limits & usage', () {
    test('canAddAnother true while below the cap', () async {
      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)), maxSeats: 3);
      await addActiveEmployees(2); // 2 < 3
      expect(await service.liveUsageOf(EntitlementResource.seats), 2);
      expect(await service.canAddAnother(EntitlementResource.seats), isTrue);
      expect(service.effectiveMax(EntitlementResource.seats), 3);
    });

    test('seat cap blocks once local active employees reach the cap', () async {
      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)), maxSeats: 3);
      await addActiveEmployees(3); // at the cap — counted live from Drift
      expect(await service.liveUsageOf(EntitlementResource.seats), 3);
      expect(await service.canAddAnother(EntitlementResource.seats), isFalse);
    });

    test('branch cap blocks once local branches reach the cap', () async {
      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)), maxBranches: 2);
      await addBranches(2); // at the cap
      expect(await service.liveUsageOf(EntitlementResource.branches), 2);
      expect(await service.canAddAnother(EntitlementResource.branches), isFalse);
    });

    test('usage meter reflects local rows after recompute', () async {
      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)), maxSeats: 3);
      await addActiveEmployees(2);
      await service.recomputeLocalUsage();
      expect(service.usageOf(EntitlementResource.seats), 2);
    });

    test('unknown cap (no cache) never blocks a create', () async {
      expect(await service.canAddAnother(EntitlementResource.seats), isTrue);
      expect(service.effectiveMax(EntitlementResource.seats), isNull);
    });

    test('Growth: a null device cap means unlimited, never a block', () async {
      await seed(
        status: 'active',
        currentPeriodEnd: now.add(const Duration(days: 10)),
        maxDevices: null,
      );
      expect(service.effectiveMax(EntitlementResource.devices), isNull);
      expect(await service.canAddAnother(EntitlementResource.devices), isTrue);
    });

    test('Starter shape: 3 seats and 1 branch both block at the cap', () async {
      await seed(
        status: 'active',
        currentPeriodEnd: now.add(const Duration(days: 10)),
        maxSeats: 3,
        maxBranches: 1,
        maxDevices: 3,
      );
      await addActiveEmployees(3);
      await addBranches(1);
      expect(await service.canAddAnother(EntitlementResource.seats), isFalse);
      expect(await service.canAddAnother(EntitlementResource.branches), isFalse);
    });
  });
}
