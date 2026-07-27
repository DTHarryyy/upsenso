import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/data/iap_service.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';

/// Drives the billing page. Current-plan display is offline-first (read from
/// EntitlementService's cache); catalog/history/devices are fetched when online.
///
/// Purchasing is Google Play (Android only). The cubit queries Play for live
/// prices, listens to the purchase stream, and hands every completed purchase
/// to the server for verification — it grants nothing itself. On web the Play
/// paths are inert and the page is read-only.
class BillingCubit extends Cubit<BillingState> {
  final EntitlementService _entitlement;
  final BillingRemoteDs _remoteDs;
  final ConnectivityService _connectivity;
  final DeviceRegistrationService _deviceRegistration;
  final IapService _iap;
  final ActiveBusinessContext _activeBusiness;

  /// Play product handles kept off the equatable state (they aren't value
  /// types); keyed by product id for the buy call.
  final Map<String, ProductDetails> _detailsById = {};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  BillingCubit({
    required EntitlementService entitlement,
    required BillingRemoteDs remoteDs,
    required ConnectivityService connectivity,
    required DeviceRegistrationService deviceRegistration,
    required IapService iap,
    required ActiveBusinessContext activeBusiness,
  })  : _entitlement = entitlement,
        _remoteDs = remoteDs,
        _connectivity = connectivity,
        _deviceRegistration = deviceRegistration,
        _iap = iap,
        _activeBusiness = activeBusiness,
        super(const BillingState()) {
    // Catch purchases + restores (and interrupted deliveries) while the page
    // is open. Verification happens per event, never on the client's say-so.
    if (_iap.isSupportedPlatform) {
      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e, StackTrace st) =>
            debugPrint('[BillingCubit] purchaseStream error: $e\n$st'),
      );
    }
  }

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
      playSupported: _iap.isSupportedPlatform,
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
      // Resolve Play prices last (Android only) — a failure here never breaks
      // the rest of the page.
      if (_iap.isSupportedPlatform) {
        await _loadPlayOffers();
      }
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

  // ── Google Play purchase flow ───────────────────────────────────────────────

  /// Queries Play for live prices of the mapped SKUs and builds the offer list.
  /// Products Play doesn't return (not yet configured) are simply skipped.
  Future<void> _loadPlayOffers() async {
    try {
      final mappings = await _remoteDs.fetchPlayProducts();
      if (mappings.isEmpty) {
        emit(state.copyWith(playOffers: const []));
        return;
      }
      final ids = mappings.map((m) => m.productId).toSet();
      final query = await _iap.queryProducts(ids);
      _detailsById
        ..clear()
        ..addEntries(query.products.map((d) => MapEntry(d.id, d)));

      final offers = <PlayPlanOffer>[];
      for (final m in mappings) {
        final d = _detailsById[m.productId];
        if (d == null) continue; // not live in Play Console yet
        offers.add(PlayPlanOffer(
          planCode: m.planCode,
          billingPeriod: m.billingPeriod,
          productId: m.productId,
          basePlanId: m.basePlanId,
          priceLabel: d.price,
        ));
      }
      emit(state.copyWith(playOffers: offers));
    } catch (e, st) {
      debugPrint('[BillingCubit] Error in _loadPlayOffers: $e\n$st');
    }
  }

  /// Launch the Play purchase flow for [planCode] at [period]. The outcome
  /// arrives on the purchase stream, not from this call.
  Future<void> buyPlan(String planCode, String period) async {
    if (!_iap.isSupportedPlatform) return;
    final offer = state.playOffers.firstWhereOrNull(
      (o) => o.planCode == planCode && o.billingPeriod == period,
    );
    final details = offer == null ? null : _detailsById[offer.productId];
    if (details == null) {
      emit(state.copyWith(
        purchaseError: 'This plan isn\'t available for purchase right now.',
      ));
      return;
    }
    emit(state.copyWith(purchaseInProgress: true, clearPurchaseError: true));
    final launched =
        await _iap.buySubscription(details, accountId: _obfuscatedAccountId());
    if (!launched) {
      emit(state.copyWith(
        purchaseInProgress: false,
        purchaseError: 'Couldn\'t start the purchase. Please try again.',
      ));
    }
  }

  /// Re-emit active purchases so a reinstall / new device recovers its plan.
  Future<void> restore() async {
    if (!_iap.isSupportedPlatform) return;
    emit(state.copyWith(purchaseInProgress: true, clearPurchaseError: true));
    try {
      await _iap.restorePurchases();
      // Restored items arrive on the stream and verify there; drop the spinner.
      emit(state.copyWith(purchaseInProgress: false));
    } catch (e, st) {
      debugPrint('[BillingCubit] Error in restore: $e\n$st');
      emit(state.copyWith(
        purchaseInProgress: false,
        purchaseError: 'Couldn\'t restore purchases. Please try again.',
      ));
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      await _handlePurchase(p);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails p) async {
    switch (p.status) {
      case PurchaseStatus.pending:
        emit(state.copyWith(purchaseInProgress: true, clearPurchaseError: true));
        break;
      case PurchaseStatus.canceled:
        emit(state.copyWith(purchaseInProgress: false));
        await _iap.completePurchase(p);
        break;
      case PurchaseStatus.error:
        debugPrint('[BillingCubit] purchase error: ${p.error}');
        emit(state.copyWith(
          purchaseInProgress: false,
          purchaseError: 'The purchase couldn\'t be completed. Please try again.',
        ));
        await _iap.completePurchase(p);
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _verifyAndFinish(p);
        break;
    }
  }

  /// Server-verify a delivered purchase, then complete it and refresh. If verify
  /// fails we do NOT complete — a later retry/restore can re-verify (Play only
  /// acknowledges on a server grant, so the purchase isn't lost).
  Future<void> _verifyAndFinish(PurchaseDetails p) async {
    try {
      await _remoteDs.verifyPlayPurchase(
        productId: p.productID,
        purchaseToken: p.verificationData.serverVerificationData,
      );
      await _iap.completePurchase(p);
      await load();
      emit(state.copyWith(purchaseInProgress: false, clearPurchaseError: true));
    } catch (e, st) {
      debugPrint('[BillingCubit] Error in _verifyAndFinish: $e\n$st');
      emit(state.copyWith(
        purchaseInProgress: false,
        purchaseError:
            'We couldn\'t confirm your purchase yet. Tap Restore to retry.',
      ));
    }
  }

  /// Obfuscated account id bound to the tenant (Play anti-fraud + linkage). A
  /// sha256 of the business id — 64 hex chars, no PII.
  String? _obfuscatedAccountId() {
    final biz = _activeBusiness.businessId;
    if (biz == null || biz.isEmpty) return null;
    return sha256.convert(utf8.encode(biz)).toString();
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

  @override
  Future<void> close() {
    _purchaseSub?.cancel();
    return super.close();
  }
}
