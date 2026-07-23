import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';

/// Drives the billing page. Current-plan display is offline-first (read from
/// EntitlementService's cache); catalog/history/devices are fetched when online.
class BillingCubit extends Cubit<BillingState> {
  final EntitlementService _entitlement;
  final BillingRemoteDs _remoteDs;
  final ConnectivityService _connectivity;
  final DeviceRegistrationService _deviceRegistration;

  BillingCubit({
    required EntitlementService entitlement,
    required BillingRemoteDs remoteDs,
    required ConnectivityService connectivity,
    required DeviceRegistrationService deviceRegistration,
  })  : _entitlement = entitlement,
        _remoteDs = remoteDs,
        _connectivity = connectivity,
        _deviceRegistration = deviceRegistration,
        super(const BillingState());

  Future<void> load() async {
    // Recount seats/branches from local Drift so the usage meters are accurate
    // from the first paint — even offline, before any server sync.
    await _entitlement.recomputeLocalUsage();
    // Always render the current plan from the local entitlement cache first,
    // clearing any prior offline/failure flags for this fresh attempt.
    emit(_withEntitlement(state).copyWith(
      status: BillingStatus.ready,
      offline: false,
      catalogFailed: false,
    ));

    final online = await _connectivity.isConnected;
    if (!online) {
      emit(state.copyWith(offline: true));
      return;
    }

    // Refresh the server entitlement (usage counts, status), then the catalog.
    try {
      await _entitlement.syncEntitlement();
      final plans = await _remoteDs.fetchPlans();
      final payments = await _remoteDs.fetchPayments();
      final devices = await _remoteDs.fetchDevices();
      emit(_withEntitlement(state).copyWith(
        status: BillingStatus.ready,
        offline: false,
        catalogFailed: false,
        plans: plans,
        payments: payments,
        devices: devices,
      ));
    } catch (e, st) {
      debugPrint('[BillingCubit] Error in load: $e\n$st');
      // Online but the catalog didn't load (schema not deployed / transient).
      // Keep the cached current plan; offer a Retry, not a false "offline".
      emit(_withEntitlement(state).copyWith(
        status: BillingStatus.ready,
        offline: false,
        catalogFailed: true,
      ));
    }
  }

  Future<void> refresh() => load();

  /// Starts a plan checkout; returns the hosted checkout URL for the page to
  /// launch. Amount is computed server-side.
  Future<String> startPlanCheckout(
    String planCode,
    int planVersion,
    String billingPeriod,
  ) {
    return _remoteDs.createCheckout(
      kind: 'plan',
      planCode: planCode,
      planVersion: planVersion,
      billingPeriod: billingPeriod,
    );
  }

  Future<void> revokeDevice(String deviceUid) async {
    await _deviceRegistration.revoke(deviceUid);
    await load();
  }

  BillingState _withEntitlement(BillingState s) {
    return s.copyWith(
      planCode: _entitlement.planCode,
      effectiveStatus: _entitlement.effectiveStatus,
      cloudEnabled: _entitlement.cloudEnabled,
      daysRemaining: _entitlement.daysRemaining,
      grandfatheredPrice: _entitlement.grandfatheredPrice,
      branchUsage: _entitlement.usageOf(EntitlementResource.branches),
      seatUsage: _entitlement.usageOf(EntitlementResource.seats),
      deviceUsage: _entitlement.usageOf(EntitlementResource.devices),
      maxBranches: _entitlement.effectiveMax(EntitlementResource.branches),
      maxSeats: _entitlement.effectiveMax(EntitlementResource.seats),
      maxDevices: _entitlement.effectiveMax(EntitlementResource.devices),
    );
  }
}
