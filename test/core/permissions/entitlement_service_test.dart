import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/data/entitlement_remote_ds.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/session/active_business_context.dart';

class MockEntitlementRemoteDs extends Mock implements EntitlementRemoteDs {}

void main() {
  late AppDatabase db;
  late MockEntitlementRemoteDs remoteDs;
  late ActiveBusinessContext ctx;
  late EntitlementService service;

  const biz = 'biz-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remoteDs = MockEntitlementRemoteDs();
    ctx = ActiveBusinessContext()..set(userId: 'u1', businessId: biz);
    service = EntitlementService(
      entitlementDao: db.entitlementDao,
      entitlementRemoteDs: remoteDs,
      activeBusinessContext: ctx,
    );
  });

  tearDown(() => db.close());

  Future<void> seed({
    required String status,
    bool cloudEnabled = true,
    Map<String, dynamic> flags = const {},
    DateTime? trialEnd,
    DateTime? currentPeriodEnd,
    DateTime? graceUntil,
    DateTime? lastServerSyncAt,
    int maxBranches = 3,
    int maxSeats = 10,
    int maxDevices = 5,
  }) async {
    await db.entitlementDao.saveEntitlement(EntitlementCacheTableCompanion(
      businessId: const Value(biz),
      planCode: Value(cloudEnabled ? 'growth' : 'free'),
      status: Value(status),
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

    test('fail-open with no cache: premium UI is not bricked, but cloud is off',
        () async {
      // no seed() — fresh install offline
      expect(service.featureAllowed(AppFeature.customerDirectory), isTrue);
      expect(service.featureAllowed(AppFeature.procurement), isTrue);
      expect(service.cloudEnabled, isFalse); // cloud fails closed
    });
  });

  group('limits & usage', () {
    test('canAddAnother false only when we know the cap is reached', () async {
      await seed(status: 'active', currentPeriodEnd: now.add(const Duration(days: 10)), maxBranches: 3);
      // usage is 0 from cache (no usage row) → can add
      expect(service.canAddAnother(EntitlementResource.branches), isTrue);
      expect(service.effectiveMax(EntitlementResource.branches), 3);
    });

    test('unknown cap (no cache) never blocks a create', () async {
      expect(service.canAddAnother(EntitlementResource.seats), isTrue);
      expect(service.effectiveMax(EntitlementResource.seats), isNull);
    });
  });
}
