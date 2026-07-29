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

final _starterAnnualPd = ProductDetails(
  id: 'upsenso_starter_annual',
  title: 'Starter (Annual)',
  description: 'Cloud backup & sync',
  price: '₱1,990.00',
  rawPrice: 1990.0,
  currencyCode: 'PHP',
);

const _starterAnnualMapping = PlayProductMapping(
  productId: 'upsenso_starter_annual',
  basePlanId: 'annual',
  planCode: 'starter',
  planVersion: 1,
  billingPeriod: 'annual',
);

final _growthAnnualPd = ProductDetails(
  id: 'upsenso_growth_annual',
  title: 'Growth (Annual)',
  description: 'Full access',
  price: '₱4,990.00',
  rawPrice: 4990.0,
  currencyCode: 'PHP',
);

const _growthAnnualMapping = PlayProductMapping(
  productId: 'upsenso_growth_annual',
  basePlanId: 'annual',
  planCode: 'growth',
  planVersion: 1,
  billingPeriod: 'annual',
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
    when(() => purchaseSync.reverifyActive()).thenAnswer((_) async => true);
    when(() => iap.isAvailable()).thenAnswer((_) async => true);
    when(() => activeBusiness.businessId).thenReturn('biz-1');

    when(() => entitlement.entitlementRevision).thenReturn(revision);
    when(() => entitlement.planCode).thenReturn('starter');
    when(() => entitlement.effectiveStatus).thenReturn('active');
    when(() => entitlement.cloudEnabled).thenReturn(true);
    when(() => entitlement.daysRemaining).thenReturn(null);
    when(() => entitlement.grandfatheredPrice).thenReturn(null);
    when(() => entitlement.usageOf(any())).thenReturn(1);
    when(() => entitlement.effectiveMax(any())).thenReturn(3);
    when(() => entitlement.syncEntitlement()).thenAnswer((_) async => true);
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
      when(() => remoteDs.fetchPlayProducts()).thenAnswer((_) async => [
            _starterMapping,
            _growthMapping,
            _starterAnnualMapping,
            _growthAnnualMapping,
          ]);
      when(() => iap.queryProducts(any())).thenAnswer((_) async =>
          IapProductQuery(products: [
            _starterPd,
            _growthPd,
            _starterAnnualPd,
            _growthAnnualPd,
          ]));
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

    // Google only accepts chargeProratedPrice for a same-period upgrade, so it
    // is never safe as a blanket choice. withTimeProration credits unused time
    // and is accepted across periods.
    blocTest<BillingCubit, BillingState>(
      'upgrade replaces the owned subscription, crediting unused time',
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
              replacementMode: ReplacementMode.withTimeProration,
            )).called(1);
      },
    );

    // The reported bug: flipping the period toggle and upgrading sent
    // chargeProratedPrice for a monthly→annual switch, which Play rejects with
    // "We are unable to change your subscription plan".
    blocTest<BillingCubit, BillingState>(
      'monthly to annual never uses chargeProratedPrice',
      build: build,
      act: (c) async {
        await c.load();
        own('upsenso_starter_monthly');
        await c.buyPlan('growth', 'annual');
      },
      verify: (_) {
        verify(() => iap.buySubscription(
              _growthAnnualPd,
              accountId: any(named: 'accountId'),
              oldPurchase: any(named: 'oldPurchase'),
              replacementMode: ReplacementMode.withTimeProration,
            )).called(1);
      },
    );

    // The entitlement reads 'free' whenever a purchase was never verified — the
    // exact state this bug left every tenant in. Pricing the change against that
    // would call a Growth→Starter downgrade an upgrade. Play's owned product is
    // the only trustworthy baseline.
    blocTest<BillingCubit, BillingState>(
      'downgrade is detected from Play\'s owned product, not the entitlement',
      setUp: () => when(() => entitlement.planCode).thenReturn('free'),
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
              oldPurchase: any(named: 'oldPurchase'),
              replacementMode: ReplacementMode.deferred,
            )).called(1);
      },
    );

    // Annual→monthly on the SAME tier is cheaper per year, but deferring it
    // would strand the user for up to a year. A period change switches now.
    blocTest<BillingCubit, BillingState>(
      'annual to monthly on the same tier switches immediately',
      setUp: () => when(() => entitlement.planCode).thenReturn('starter'),
      build: build,
      act: (c) async {
        await c.load();
        own('upsenso_starter_annual');
        await c.buyPlan('starter', 'monthly');
      },
      verify: (_) {
        verify(() => iap.buySubscription(
              _starterPd,
              accountId: any(named: 'accountId'),
              oldPurchase: any(named: 'oldPurchase'),
              replacementMode: ReplacementMode.withTimeProration,
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

    // Buying something Play already owns fails with ITEM_ALREADY_OWNED. What the
    // user is actually missing is the grant, so re-verify rather than opening a
    // purchase sheet that cannot succeed.
    blocTest<BillingCubit, BillingState>(
      'tapping the plan Play already owns re-verifies instead of buying',
      build: build,
      act: (c) async {
        await c.load();
        await ownStarter(c);
        await c.buyPlan('starter', 'monthly');
      },
      verify: (c) {
        verify(() => purchaseSync.reverifyActive()).called(1);
        verifyNever(() => iap.buySubscription(
              any(),
              accountId: any(named: 'accountId'),
              oldPurchase: any(named: 'oldPurchase'),
              replacementMode: any(named: 'replacementMode'),
            ));
        expect(c.state.purchaseInProgress, isFalse);
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

    // The restore that populates `oldPurchaseDetails` was fire-and-forget, so an
    // Upgrade tapped before it landed went out with oldPurchase: null — and Play
    // then STACKED a second, separately-billed subscription instead of replacing.
    blocTest<BillingCubit, BillingState>(
      'buyPlan waits for the in-flight restore before reading what Play owns',
      setUp: () {
        when(() => entitlement.planCode).thenReturn('free');
        // Play answers slowly, and only then reports the owned subscription.
        when(() => purchaseSync.restore()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          when(() => purchaseSync.activePurchase)
              .thenReturn(_ownedPurchase('upsenso_starter_monthly'));
        });
      },
      build: build,
      act: (c) async {
        await c.load();
        await c.buyPlan('growth', 'monthly');
      },
      verify: (_) {
        final captured = verify(() => iap.buySubscription(
              _growthPd,
              accountId: any(named: 'accountId'),
              oldPurchase: captureAny(named: 'oldPurchase'),
              replacementMode: any(named: 'replacementMode'),
            )).captured;
        expect(
          (captured.single as PurchaseDetails?)?.productID,
          'upsenso_starter_monthly',
        );
      },
    );

    // granted → load() → restore() → Play re-emits → verify → granted → …
    // Unbounded while the page is open, one edge-function invoke per lap.
    blocTest<BillingCubit, BillingState>(
      'load does not restore again once Play has already reported a purchase',
      setUp: () {
        when(() => purchaseSync.activePurchase)
            .thenReturn(_ownedPurchase('upsenso_growth_monthly'));
      },
      build: build,
      act: (c) => c.load(),
      verify: (_) => verifyNever(() => purchaseSync.restore()),
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

    // THE reported bug, end to end: upgrading to Growth granted correctly, but
    // the trailing restore surfaced the replaced Starter token, whose verify
    // 409'd — and the user got a blocking "we couldn't confirm your purchase"
    // over a plan card already showing Growth.
    blocTest<BillingCubit, BillingState>(
      'a superseded old token after an upgrade shows the user nothing',
      setUp: () {
        when(() => iap.isSupportedPlatform).thenReturn(true);
        when(() => connectivity.isConnected).thenAnswer((_) async => false);
        when(() => entitlement.planCode).thenReturn('growth');
      },
      build: build,
      act: (c) async {
        purchaseEvents.add(const PlayPurchaseEvent(PlayPurchasePhase.granted));
        await Future<void>.delayed(Duration.zero);
        purchaseEvents
            .add(const PlayPurchaseEvent(PlayPurchasePhase.superseded));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (c) {
        expect(c.state.planCode, 'growth');
        expect(c.state.purchaseAlert, isNull);
        expect(c.state.purchaseError, isNull);
        expect(c.state.purchaseInProgress, isFalse);
      },
    );

    blocTest<BillingCubit, BillingState>(
      'backing out of a purchase clears the error left by the attempt',
      setUp: () {
        when(() => iap.isSupportedPlatform).thenReturn(true);
        when(() => connectivity.isConnected).thenAnswer((_) async => false);
      },
      build: build,
      act: (c) async {
        purchaseEvents.add(const PlayPurchaseEvent(
          PlayPurchasePhase.failed,
          message: 'something went wrong',
        ));
        await Future<void>.delayed(Duration.zero);
        expect(c.state.purchaseError, isNotNull);
        purchaseEvents.add(const PlayPurchaseEvent(PlayPurchasePhase.canceled));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (c) => expect(c.state.purchaseError, isNull),
    );

    // An entitlement repaint used to preserve purchaseError, so a dead message
    // sat beside a plan card that had already moved on.
    blocTest<BillingCubit, BillingState>(
      'an entitlement change clears a stale purchase error',
      setUp: () {
        when(() => iap.isSupportedPlatform).thenReturn(true);
        when(() => connectivity.isConnected).thenAnswer((_) async => false);
      },
      build: build,
      act: (c) async {
        purchaseEvents.add(const PlayPurchaseEvent(
          PlayPurchasePhase.failed,
          message: 'stale',
        ));
        await Future<void>.delayed(Duration.zero);
        when(() => entitlement.planCode).thenReturn('growth');
        revision.value++;
        await Future<void>.delayed(Duration.zero);
      },
      verify: (c) {
        expect(c.state.planCode, 'growth');
        expect(c.state.purchaseError, isNull);
      },
    );

    // The grant landed server-side but this device couldn't refresh. That is a
    // notice, not an error — the plan really is active.
    //
    // Asserted on the emitted state, not the final one: a notice describes a
    // moment and is deliberately non-sticky, so the reload that follows a grant
    // clears it. The page shows it via a listener, which sees every state.
    test('a granted event carrying a message surfaces it as a notice', () async {
      when(() => iap.isSupportedPlatform).thenReturn(true);
      when(() => connectivity.isConnected).thenAnswer((_) async => false);
      final cubit = build();
      final notices = <String?>[];
      final errors = <String?>[];
      final sub = cubit.stream.listen((s) {
        notices.add(s.purchaseNotice);
        errors.add(s.purchaseError);
      });

      purchaseEvents.add(const PlayPurchaseEvent(
        PlayPurchasePhase.granted,
        message: 'Your plan is active. Refreshing this device…',
      ));
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      await cubit.close();
      expect(notices, contains(contains('active')));
      expect(errors.every((e) => e == null), isTrue);
    });
  });

  // The probe exists so a broken Play setup can be found without charging
  // anyone — that only holds if a failing check still reaches the user.
  group('config probe', () {
    blocTest<BillingCubit, BillingState>(
      'surfaces failing checks rather than only a pass/fail',
      setUp: () {
        when(() => connectivity.isConnected).thenAnswer((_) async => false);
        when(() => remoteDs.probePlayConfig()).thenAnswer((_) async => const [
              BillingProbeCheck(
                stage: 'secrets',
                ok: true,
                detail: 'package "com.ledgidy.pos", key secret 2300 chars',
              ),
              BillingProbeCheck(
                stage: 'google_app_access',
                ok: false,
                detail: 'subscriptions.list failed: 403',
              ),
            ]);
      },
      build: build,
      act: (c) => c.runConfigProbe(),
      verify: (c) {
        expect(c.state.probeRunning, isFalse);
        expect(c.state.probeError, isNull);
        expect(c.state.probeChecks.length, 2);
        expect(c.state.probeChecks.last.ok, isFalse);
        expect(c.state.probeChecks.last.label, 'Play Store access');
      },
    );

    blocTest<BillingCubit, BillingState>(
      'a probe that cannot run reports an error and clears the spinner',
      setUp: () {
        when(() => connectivity.isConnected).thenAnswer((_) async => false);
        when(() => remoteDs.probePlayConfig())
            .thenThrow(const PlayVerifyException(500, 'boom'));
      },
      build: build,
      act: (c) => c.runConfigProbe(),
      verify: (c) {
        expect(c.state.probeRunning, isFalse);
        expect(c.state.probeError, isNotNull);
        expect(c.state.probeChecks, isEmpty);
      },
    );
  });

  // Leaving the Billing page mid-load closed the cubit while the catalog fetch
  // was still in flight, and the emit that followed threw
  // "Cannot emit new states after calling close".
  group('closing mid-flight', () {
    test('a load still in flight when the page closes does not throw', () async {
      final gate = Completer<List<PlanOption>>();
      when(() => connectivity.isConnected).thenAnswer((_) async => true);
      when(() => remoteDs.fetchPlans()).thenAnswer((_) => gate.future);
      when(() => remoteDs.fetchPayments()).thenAnswer((_) async => []);
      when(() => remoteDs.fetchDevices()).thenAnswer((_) async => []);

      final cubit = build();
      final pending = cubit.load();

      await cubit.close(); // user pops the page
      gate.complete([_starter]); // the fetch lands afterwards

      await expectLater(pending, completes);
    });

    test('a purchase event arriving after close does not throw', () async {
      when(() => iap.isSupportedPlatform).thenReturn(true);
      when(() => connectivity.isConnected).thenAnswer((_) async => false);

      final cubit = build();
      await cubit.close();

      purchaseEvents.add(const PlayPurchaseEvent(
        PlayPurchasePhase.stuck,
        message: 'charged but not granted',
      ));

      await expectLater(
        Future<void>.delayed(const Duration(milliseconds: 10)),
        completes,
      );
    });
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
