import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';

class _MockEntitlement extends Mock implements EntitlementService {}

class _MockRemoteDs extends Mock implements BillingRemoteDs {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockDeviceReg extends Mock implements DeviceRegistrationService {}

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

void main() {
  late _MockEntitlement entitlement;
  late _MockRemoteDs remoteDs;
  late _MockConnectivity connectivity;
  late _MockDeviceReg deviceReg;

  setUpAll(() {
    registerFallbackValue(EntitlementResource.branches);
  });

  setUp(() {
    entitlement = _MockEntitlement();
    remoteDs = _MockRemoteDs();
    connectivity = _MockConnectivity();
    deviceReg = _MockDeviceReg();

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

  group('startPlanCheckout', () {
    test('delegates to the data source with kind=plan', () async {
      when(() => remoteDs.createCheckout(
            kind: any(named: 'kind'),
            planCode: any(named: 'planCode'),
            planVersion: any(named: 'planVersion'),
            billingPeriod: any(named: 'billingPeriod'),
          )).thenAnswer((_) async => 'https://pay.example/x');

      final url = await build().startPlanCheckout('growth', 1, 'annual');

      expect(url, 'https://pay.example/x');
      verify(() => remoteDs.createCheckout(
            kind: 'plan',
            planCode: 'growth',
            planVersion: 1,
            billingPeriod: 'annual',
          )).called(1);
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
