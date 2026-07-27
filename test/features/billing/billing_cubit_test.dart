import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/data/iap_service.dart';
import 'package:pos/features/billing/data/play_purchase_sync_service.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';

class _MockEntitlement extends Mock implements EntitlementService {}

class _MockRemoteDs extends Mock implements BillingRemoteDs {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockDeviceReg extends Mock implements DeviceRegistrationService {}

class _MockIap extends Mock implements IapService {}

class _MockPurchaseSync extends Mock implements PlayPurchaseSyncService {}

class _MockActiveBusiness extends Mock implements ActiveBusinessContext {}

const _starter = PlanOption(
  code: 'starter',
  version: 1,
  name: 'Starter',
  priceMonthly: 199,
  isActive: true,
  cloudEnabled: true,
  maxBranches: 1,
  maxSeats: 3,
  maxDevices: 2,
);

final _starterPd = ProductDetails(
  id: 'upsenso_starter_monthly',
  title: 'Starter (Monthly)',
  description: 'Cloud backup & sync',
  price: '₱199.00',
  rawPrice: 199.0,
  currencyCode: 'PHP',
);

const _starterMapping = PlayProductMapping(
  productId: 'upsenso_starter_monthly',
  basePlanId: 'monthly',
  planCode: 'starter',
  planVersion: 1,
  billingPeriod: 'monthly',
);

const _growth = PlanOption(
  code: 'growth',
  version: 1,
  name: 'Growth',
  priceMonthly: 499,
  isActive: true,
  cloudEnabled: true,
  maxBranches: 3,
  maxSeats: 10,
  maxDevices: 5,
);

final _growthPd = ProductDetails(
  id: 'upsenso_growth_monthly',
  title: 'Growth (Monthly)',
  description: 'Full access',
  price: '₱499.00',
  rawPrice: 499.0,
  currencyCode: 'PHP',
);

const _growthMapping = PlayProductMapping(
  productId: 'upsenso_growth_monthly',
  basePlanId: 'monthly',
  planCode: 'growth',
  planVersion: 1,
  billingPeriod: 'monthly',
);

PurchaseDetails _ownedPurchase(String productId) => PurchaseDetails(
      purchaseID: 'order-$productId',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: 'token-$productId',
        source: 'google_play',
      ),
      transactionDate: '1700000000000',
      status: PurchaseStatus.purchased,
    );

void main() {
  late _MockEntitlement entitlement;
  late _MockRemoteDs remoteDs;
  late _MockConnectivity connectivity;
  late _MockDeviceReg deviceReg;
  late _MockIap iap;
  late _MockPurchaseSync purchaseSync;
  late _MockActiveBusiness activeBusiness;
  late ValueNotifier<int> revision;
  late StreamController<PlayPurchaseEvent> purchaseEvents;

  setUpAll(() {
    registerFallbackValue(EntitlementResource.branches);
    registerFallbackValue(<String>{});
    registerFallbackValue(_starterPd);
    registerFallbackValue(_ownedPurchase('fallback'));
    registerFallbackValue(ReplacementMode.unknownReplacementMode);
  });

  setUp(() {
    entitlement = _MockEntitlement();
    remoteDs = _MockRemoteDs();
    connectivity = _MockConnectivity();
    deviceReg = _MockDeviceReg();
    iap = _MockIap();
    purchaseSync = _MockPurchaseSync();
    activeBusiness = _MockActiveBusiness();
    revision = ValueNotifier<int>(0);
    purchaseEvents = StreamController<PlayPurchaseEvent>.broadcast();

    // Default: not on a Play platform — exercises the non-purchase paths.
    when(() => iap.isSupportedPlatform).thenReturn(false);
    when(() => iap.purchaseStream)
        .thenAnswer((_) => const Stream<List<PurchaseDetails>>.empty());
    when(() => purchaseSync.events).thenAnswer((_) => purchaseEvents.stream);
    when(() => purchaseSync.activePurchase).thenReturn(null);
    when(() => purchaseSync.restore()).thenAnswer((_) async {});
    when(() => activeBusiness.businessId).thenReturn('biz-1');

    when(() => entitlement.entitlementRevision).thenReturn(revision);
    when(() => entitlement.planCode).thenReturn('starter');
    when(() => entitlement.effectiveStatus).thenReturn('active');
    when(() => entitlement.cloudEnabled).thenReturn(true);
    when(() => entitlement.daysRemaining).thenReturn(null);
    when(() => entitlement.grandfatheredPrice).thenReturn(null);
    when(() => entitlement.usageOf(any())).thenReturn(1);
    when(() => entitlement.effectiveMax(any())).thenReturn(3);
    when(() => entitlement.syncEntitlement()).thenAnswer((_) async {});
    when(() => entitlement.recomputeLocalUsage()).thenAnswer((_) async {});
  });

  tearDown(() {
    purchaseEvents.close();
    revision.dispose();
  });

  BillingCubit build() => BillingCubit(
        entitlement: entitlement,
        remoteDs: remoteDs,
        connectivity: connectivity,
        deviceRegistration: deviceReg,
        iap: iap,
        purchaseSync: purchaseSync,
        activeBusiness: activeBusiness,
      );

  group('load', () {
    blocTest<BillingCubit, BillingState>(
      'offline: renders cached plan, sets offline, never fetches catalog',
      setUp: () =>
          when(() => connectivity.isConnected).thenAnswer((_) async => false),
      build: build,
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.status, BillingStatus.ready);
        expect(c.state.offline, isTrue);
        expect(c.state.planCode, 'starter');
        expect(c.state.plans, isEmpty);
        verifyNever(() => remoteDs.fetchPlans());
      },
    );

    blocTest<BillingCubit, BillingState>(
      'online: syncs entitlement, loads catalog + payments + devices',
      setUp: () {
        when(() => connectivity.isConnected).thenAnswer((_) async => true);
        when(() => remoteDs.fetchPlans()).thenAnswer((_) async => [_starter]);
        when(() => remoteDs.fetchPayments()).thenAnswer((_) async => []);
        when(() => remoteDs.fetchDevices()).thenAnswer((_) async => []);
      },
      build: build,
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.status, BillingStatus.ready);
        expect(c.state.offline, isFalse);
        expect(c.state.catalogFailed, isFalse);
        expect(c.state.plans, [_starter]);
        verify(() => entitlement.syncEntitlement()).called(1);
      },
    );

    blocTest<BillingCubit, BillingState>(
      'online but catalog fails: keeps cached plan, flags catalogFailed',
      setUp: () {
        when(() => connectivity.isConnected).thenAnswer((_) async => true);
        when(() => remoteDs.fetchPlans()).thenThrow(Exception('boom'));
      },
      build: build,
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.status, BillingStatus.ready);
        expect(c.state.offline, isFalse);
        expect(c.state.catalogFailed, isTrue);
        expect(c.state.planCode, 'starter');
      },
    );
  });

  group('google play', () {
    // Stubs the online catalog + Play SKU resolution for an Android session.
    void stubAndroidCatalog() {
      when(() => iap.isSupportedPlatform).thenReturn(true);
      when(() => connectivity.isConnected).thenAnswer((_) async => true);
      when(() => remoteDs.fetchPlans()).thenAnswer((_) async => [_starter]);
      when(() => remoteDs.fetchPayments()).thenAnswer((_) async => []);
      when(() => remoteDs.fetchDevices()).thenAnswer((_) async => []);
      when(() => remoteDs.fetchPlayProducts())
          .thenAnswer((_) async => [_starterMapping]);
      when(() => iap.queryProducts(any()))
          .thenAnswer((_) async => IapProductQuery(products: [_starterPd]));
    }

    blocTest<BillingCubit, BillingState>(
      'buyPlan is a no-op when Play is unsupported',
      build: build,
      act: (c) => c.buyPlan('starter', 'monthly'),
      verify: (_) {
        verifyNever(() =>
            iap.buySubscription(any(), accountId: any(named: 'accountId')));
      },
    );

    blocTest<BillingCubit, BillingState>(
      'Android load resolves Play offers from the SKU map + store prices',
      setUp: stubAndroidCatalog,
      build: build,
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.playSupported, isTrue);
        expect(c.state.playOffers.length, 1);
        expect(c.state.playOffers.first.priceLabel, '₱199.00');
        expect(c.state.playOffers.first.planCode, 'starter');
      },
    );

    blocTest<BillingCubit, BillingState>(
      'buyPlan launches the Play flow with an obfuscated account id',
      setUp: () {
        stubAndroidCatalog();
        when(() => iap.buySubscription(_starterPd,
            accountId: any(named: 'accountId'))).thenAnswer((_) async => true);
      },
      build: build,
      act: (c) async {
        await c.load();
        await c.buyPlan('starter', 'monthly');
      },
      verify: (c) {
        expect(c.state.purchaseInProgress, isTrue);
        verify(() => iap.buySubscription(_starterPd,
            accountId: any(named: 'accountId'))).called(1);
      },
    );

    blocTest<BillingCubit, BillingState>(
      'buyPlan surfaces an error when the plan has no purchasable offer',
      setUp: () => when(() => iap.isSupportedPlatform).thenReturn(true),
      build: build,
      act: (c) => c.buyPlan('growth', 'monthly'),
      verify: (c) {
        expect(c.state.purchaseError, isNotNull);
        verifyNever(() =>
            iap.buySubscription(any(), accountId: any(named: 'accountId')));
      },
    );
  });

  // A tenant switching tiers must REPLACE its existing Play subscription —
  // sending the buy without oldPurchase leaves both subscriptions billing.
  group('google play plan changes', () {
    setUp(() {
      when(() => iap.isSupportedPlatform).thenReturn(true);
      when(() => connectivity.isConnected).thenAnswer((_) async => true);
      when(() => remoteDs.fetchPlans())
          .thenAnswer((_) async => [_starter, _growth]);
      when(() => remoteDs.fetchPayments()).thenAnswer((_) async => []);
      when(() => remoteDs.fetchDevices()).thenAnswer((_) async => []);
      when(() => remoteDs.fetchPlayProducts())
          .thenAnswer((_) async => [_starterMapping, _growthMapping]);
      when(() => iap.queryProducts(any())).thenAnswer(
          (_) async => IapProductQuery(products: [_starterPd, _growthPd]));
      when(() => iap.restorePurchases()).thenAnswer((_) async {});
      when(() => iap.completePurchase(any())).thenAnswer((_) async {});
      when(() => remoteDs.verifyPlayPurchase(
            productId: any(named: 'productId'),
            purchaseToken: any(named: 'purchaseToken'),
          )).thenAnswer((_) async {});
      when(() => iap.buySubscription(
            any(),
            accountId: any(named: 'accountId'),
            oldPurchase: any(named: 'oldPurchase'),
            replacementMode: any(named: 'replacementMode'),
          )).thenAnswer((_) async => true);
    });

    // What Play reports the tenant currently owns. The cubit reads this from
    // the app-scoped sync service rather than tracking the stream itself.
    void own(String productId) {
      when(() => purchaseSync.activePurchase)
          .thenReturn(_ownedPurchase(productId));
    }

    Future<void> ownStarter(BillingCubit c) async {
      own('upsenso_starter_monthly');
    }

    blocTest<BillingCubit, BillingState>(
      'upgrade replaces the owned subscription and charges the difference now',
      build: build,
      act: (c) async {
        await c.load();
        await ownStarter(c);
        await c.buyPlan('growth', 'monthly');
      },
      verify: (_) {
        verify(() => iap.buySubscription(
              _growthPd,
              accountId: any(named: 'accountId'),
              oldPurchase: any(
                named: 'oldPurchase',
                that: isA<PurchaseDetails>().having(
                  (p) => p.productID,
                  'productID',
                  'upsenso_starter_monthly',
                ),
              ),
              replacementMode: ReplacementMode.chargeProratedPrice,
            )).called(1);
      },
    );

    blocTest<BillingCubit, BillingState>(
      'downgrade defers the switch to renewal so paid time is not lost',
      setUp: () => when(() => entitlement.planCode).thenReturn('growth'),
      build: build,
      act: (c) async {
        await c.load();
        own('upsenso_growth_monthly');
        await c.buyPlan('starter', 'monthly');
      },
      verify: (_) {
        verify(() => iap.buySubscription(
              _starterPd,
              accountId: any(named: 'accountId'),
              oldPurchase: any(
                named: 'oldPurchase',
                that: isA<PurchaseDetails>().having(
                  (p) => p.productID,
                  'productID',
                  'upsenso_growth_monthly',
                ),
              ),
              replacementMode: ReplacementMode.deferred,
            )).called(1);
      },
    );

    blocTest<BillingCubit, BillingState>(
      'rebuying the owned product sends no change param',
      build: build,
      act: (c) async {
        await c.load();
        await ownStarter(c);
        await c.buyPlan('starter', 'monthly');
      },
      verify: (_) {
        final captured = verify(() => iap.buySubscription(
              _starterPd,
              accountId: any(named: 'accountId'),
              oldPurchase: captureAny(named: 'oldPurchase'),
              replacementMode: any(named: 'replacementMode'),
            )).captured;
        expect(captured.single, isNull);
      },
    );

    blocTest<BillingCubit, BillingState>(
      'first purchase on a free plan sends no change param',
      setUp: () => when(() => entitlement.planCode).thenReturn('free'),
      build: build,
      act: (c) async {
        await c.load();
        await c.buyPlan('starter', 'monthly');
      },
      verify: (_) {
        final captured = verify(() => iap.buySubscription(
              _starterPd,
              accountId: any(named: 'accountId'),
              oldPurchase: captureAny(named: 'oldPurchase'),
              replacementMode: any(named: 'replacementMode'),
            )).captured;
        expect(captured.single, isNull);
      },
    );
  });

  // Regression: the page renders a COPY of the entitlement. Without these the
  // plan only refreshed on a full restart (S2).
  group('entitlement changes repaint the page', () {
    blocTest<BillingCubit, BillingState>(
      'a revision bump re-reads the plan with no reload',
      setUp: () =>
          when(() => connectivity.isConnected).thenAnswer((_) async => false),
      build: build,
      act: (c) async {
        await c.load();
        // Simulates an RTDN-driven grant landing via a background sync.
        when(() => entitlement.planCode).thenReturn('growth');
        when(() => entitlement.effectiveStatus).thenReturn('active');
        revision.value++;
      },
      verify: (c) {
        expect(c.state.planCode, 'growth');
        expect(c.state.effectiveStatus, 'active');
      },
    );

    blocTest<BillingCubit, BillingState>(
      'a trial ending clears daysRemaining instead of stranding it',
      setUp: () {
        when(() => connectivity.isConnected).thenAnswer((_) async => false);
        when(() => entitlement.effectiveStatus).thenReturn('trialing');
        when(() => entitlement.daysRemaining).thenReturn(2);
      },
      build: build,
      act: (c) async {
        await c.load();
        expect(c.state.daysRemaining, 2);
        when(() => entitlement.effectiveStatus).thenReturn('active');
        when(() => entitlement.daysRemaining).thenReturn(null);
        revision.value++;
      },
      verify: (c) => expect(c.state.daysRemaining, isNull),
    );
  });

  group('purchase events drive the spinner only', () {
    blocTest<BillingCubit, BillingState>(
      'a failed purchase surfaces the service message and clears the spinner',
      setUp: () {
        when(() => iap.isSupportedPlatform).thenReturn(true);
        when(() => connectivity.isConnected).thenAnswer((_) async => false);
      },
      build: build,
      act: (c) async {
        purchaseEvents.add(const PlayPurchaseEvent(PlayPurchasePhase.pending));
        await Future<void>.delayed(Duration.zero);
        expect(c.state.purchaseInProgress, isTrue);
        purchaseEvents.add(const PlayPurchaseEvent(
          PlayPurchasePhase.failed,
          message: 'nope',
        ));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (c) {
        expect(c.state.purchaseInProgress, isFalse);
        expect(c.state.purchaseError, 'nope');
      },
    );

    blocTest<BillingCubit, BillingState>(
      'restore delegates to the app-scoped service, not the store directly',
      setUp: () {
        when(() => iap.isSupportedPlatform).thenReturn(true);
        when(() => connectivity.isConnected).thenAnswer((_) async => false);
      },
      build: build,
      act: (c) => c.restore(),
      verify: (_) {
        verify(() => purchaseSync.restore()).called(1);
        verifyNever(() => iap.restorePurchases());
      },
    );
  });

  group('revokeDevice', () {
    blocTest<BillingCubit, BillingState>(
      'revokes then reloads',
      setUp: () {
        when(() => deviceReg.revoke(any())).thenAnswer((_) async {});
        when(() => connectivity.isConnected).thenAnswer((_) async => false);
      },
      build: build,
      act: (c) => c.revokeDevice('dev-1'),
      verify: (c) {
        verify(() => deviceReg.revoke('dev-1')).called(1);
        // Reload ran: the offline flag from the second load() pass is set.
        expect(c.state.offline, isTrue);
      },
    );
  });
}
