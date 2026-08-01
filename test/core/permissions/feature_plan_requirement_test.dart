import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/data/entitlement_remote_ds.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/feature_plan_requirement.dart';
import 'package:pos/core/session/active_business_context.dart';

class MockEntitlementRemoteDs extends Mock implements EntitlementRemoteDs {}

/// Regression cover for the "Unusual Activity does nothing" bug: the router
/// guard denied `/more/fraud` on every tier below Growth while both nav
/// builders still rendered a plain, tappable item — a visible control wired to
/// a guard it could never pass. `planLockFor` is what now keeps the two in
/// step, so it must agree with `featureAllowed` on every tier.
void main() {
  late AppDatabase db;
  late EntitlementService entitlement;
  const biz = 'biz-1';

  setUp(() async {
    await sl.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final ctx = ActiveBusinessContext()..set(userId: 'u1', businessId: biz);
    entitlement = EntitlementService(
      entitlementDao: db.entitlementDao,
      entitlementRemoteDs: MockEntitlementRemoteDs(),
      activeBusinessContext: ctx,
      employeesDao: EmployeesDao(db),
      branchesDao: BranchesDao(db),
    );
    sl.registerSingleton<EntitlementService>(entitlement);
  });

  tearDown(() async {
    await sl.reset();
    await db.close();
  });

  /// Mirrors the live plan_limits rows (20260731124330_plan_limits_retune).
  Future<void> seedTier(String planCode) async {
    const flagsByTier = {
      'free': {
        'crm': false,
        'procurement': false,
        'reports': 'basic',
        'audit': 'local',
      },
      'starter': {
        'crm': 'basic',
        'procurement': false,
        'reports': 'basic',
        'audit': 'cloud',
      },
      'growth': {
        'crm': 'full',
        'procurement': true,
        'reports': 'full',
        'audit': 'full',
      },
    };
    await db.entitlementDao.saveEntitlement(EntitlementCacheTableCompanion(
      businessId: const Value(biz),
      planCode: Value(planCode),
      status: const Value('active'),
      featureFlagsJson: Value(json.encode(flagsByTier[planCode]!)),
      currentPeriodEnd: Value(DateTime.now().add(const Duration(days: 20))),
    ));
    await entitlement.loadFromCache();
  }

  group('requiredPlanFor', () {
    test('names the tier that unlocks each paid feature', () {
      expect(requiredPlanFor(AppFeature.customerDirectory), 'starter');
      expect(requiredPlanFor(AppFeature.procurement), 'growth');
      expect(requiredPlanFor(AppFeature.supplierDirectory), 'growth');
      // The two audit surfaces sit on different rungs — the log opens at
      // Starter, the dashboard is Growth.
      expect(requiredPlanFor(AppFeature.auditLogs), 'starter');
      expect(requiredPlanFor(AppFeature.fraudAlerts), 'growth');
    });

    test('features on every tier have nothing to upsell', () {
      expect(requiredPlanFor(AppFeature.posTerminal), isNull);
      expect(requiredPlanFor(AppFeature.inventoryManagement), isNull);
      expect(requiredPlanFor(AppFeature.salesHistory), isNull);
      expect(requiredPlanFor(AppFeature.billingSubscription), isNull);
    });
  });

  group('planLockFor agrees with featureAllowed', () {
    // The bug in one assertion: on Free the item must be badged, never plain.
    test('Free badges Unusual Activity as Growth', () async {
      await seedTier('free');
      expect(entitlement.featureAllowed(AppFeature.fraudAlerts), isFalse);
      expect(planLockFor(AppFeature.fraudAlerts), 'growth');
    });

    test('Free badges the Audit Log as Starter, not Growth', () async {
      await seedTier('free');
      expect(entitlement.featureAllowed(AppFeature.auditLogs), isFalse);
      expect(planLockFor(AppFeature.auditLogs), 'starter');
    });

    // The proof the two features genuinely diverged rather than moving as one:
    // the same tier opens one and badges the other.
    test('Starter opens the Audit Log but still badges Unusual Activity',
        () async {
      await seedTier('starter');
      expect(entitlement.featureAllowed(AppFeature.auditLogs), isTrue);
      expect(planLockFor(AppFeature.auditLogs), isNull);

      expect(entitlement.featureAllowed(AppFeature.fraudAlerts), isFalse);
      expect(planLockFor(AppFeature.fraudAlerts), 'growth');
      // ...and CRM has opened up by then too.
      expect(planLockFor(AppFeature.customerDirectory), isNull);
    });

    test('Growth badges nothing — every gated feature is included', () async {
      await seedTier('growth');
      for (final f in [
        AppFeature.fraudAlerts,
        AppFeature.auditLogs,
        AppFeature.customerDirectory,
        AppFeature.procurement,
        AppFeature.supplierDirectory,
      ]) {
        expect(entitlement.featureAllowed(f), isTrue, reason: '$f allowed');
        expect(planLockFor(f), isNull, reason: '$f unbadged');
      }
    });

    test('a lock is never reported for a feature the plan allows', () async {
      for (final tier in ['free', 'starter', 'growth']) {
        await seedTier(tier);
        for (final f in AppFeature.values) {
          if (entitlement.featureAllowed(f)) {
            expect(planLockFor(f), isNull, reason: '$tier / $f');
          }
        }
      }
    });

    test('no cache fails open, so nothing is badged', () {
      // Fresh install on a paid tenant: never brick premium UI before the
      // entitlement lands.
      expect(planLockFor(AppFeature.fraudAlerts), isNull);
    });
  });
}
