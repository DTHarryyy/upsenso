import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/data/iap_service.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';

class _MockEntitlement extends Mock implements EntitlementService {}

class _MockRemoteDs extends Mock implements BillingRemoteDs {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockDeviceReg extends Mock implements DeviceRegistrationService {}

class _MockIap extends Mock implements IapService {}

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

void main() {
  late _MockEntitlement entitlement;
  late _MockRemoteDs remoteDs;
  late _MockConnectivity connectivity;
  late _MockDeviceReg deviceReg;
  late _MockIap iap;
  late _MockActiveBusiness activeBusiness;

  setUpAll(() {
    registerFallbackValue(EntitlementResource.branches);
    registerFallbackValue(<String>{});
    registerFallbackValue(_starterPd);
  });

  setUp(() {
    entitlement = _MockEntitlement();
    remoteDs = _MockRemoteDs();
    connectivity = _MockConnectivity();
    deviceReg = _MockDeviceReg();
    iap = _MockIap();
    activeBusiness = _MockActiveBusiness();

    // Default: not on a Play platform — exercises the non-purchase paths.
    when(() => iap.isSupportedPlatform).thenReturn(false);
    when(() => iap.purchaseStream)
        .thenAnswer((_) => const Stream<List<PurchaseDetails>>.empty());
    when(() => activeBusiness.businessId).thenReturn('biz-1');

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

  BillingCubit build() => BillingCubit(
        entitlement: entitlement,
        remoteDs: remoteDs,
        connectivity: connectivity,
        deviceRegistration: deviceReg,
        iap: iap,
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
