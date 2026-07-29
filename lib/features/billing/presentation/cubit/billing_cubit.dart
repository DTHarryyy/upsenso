import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/data/iap_service.dart';
import 'package:pos/features/billing/data/play_purchase_sync_service.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';

/// Drives the billing page. Current-plan display is offline-first (read from
/// EntitlementService's cache); catalog/history/devices are fetched when online.
///
/// Purchasing is Google Play (Android only). The cubit queries Play for live
/// prices and launches the buy flow, but it neither verifies nor completes a
/// purchase — PlayPurchaseSyncService owns that for the whole app lifetime, and
/// this listens to it only for spinner/error feedback. On web the Play paths
/// are inert and the page is read-only.
class BillingCubit extends Cubit<BillingState> {
  final EntitlementService _entitlement;
  final BillingRemoteDs _remoteDs;
  final ConnectivityService _connectivity;
  final DeviceRegistrationService _deviceRegistration;
  final IapService _iap;
  final PlayPurchaseSyncService _purchaseSync;
  final ActiveBusinessContext _activeBusiness;

  /// Play product handles kept off the equatable state (they aren't value
  /// types). Keyed by product id AND base plan id: Play returns one entry per
  /// base plan and per discounted offer, all sharing the product id, so the id
  /// alone is not a unique key.
  final Map<String, ProductDetails> _detailsByOffer = {};
  StreamSubscription<PlayPurchaseEvent>? _purchaseEventSub;

  /// The restore kicked off by [load]. A plan change needs Play's owned purchase
  /// as `oldPurchaseDetails`, so [buyPlan] waits for this before reading it —
  /// tapping Upgrade while it was still in flight sent `oldPurchase: null` and
  /// Play stacked a second, separately-billed subscription.
  Future<void>? _pendingRestore;

  /// How long buyPlan will wait for that restore. Long enough for a normal Play
  /// round trip, short enough that a hung store doesn't strand the button.
  static const _restoreWait = Duration(seconds: 3);

  static String _offerKey(String productId, String basePlanId) =>
      '$productId|$basePlanId';

  BillingCubit({
    required EntitlementService entitlement,
    required BillingRemoteDs remoteDs,
    required ConnectivityService connectivity,
    required DeviceRegistrationService deviceRegistration,
    required IapService iap,
    required PlayPurchaseSyncService purchaseSync,
    required ActiveBusinessContext activeBusiness,
  })  : _entitlement = entitlement,
        _remoteDs = remoteDs,
        _connectivity = connectivity,
        _deviceRegistration = deviceRegistration,
        _iap = iap,
        _purchaseSync = purchaseSync,
        _activeBusiness = activeBusiness,
        super(const BillingState()) {
    if (_iap.isSupportedPlatform) {
      _purchaseEventSub = _purchaseSync.events.listen(
        _onPurchaseEvent,
        onError: (Object e, StackTrace st) =>
            debugPrint('[BillingCubit] purchase events error: $e\n$st'),
      );
    }
    // The page renders a copy of the entitlement, so it has to be told when the
    // original changes — an RTDN-driven renewal or cancel lands via a
    // background sync, not through load().
    _entitlement.entitlementRevision.addListener(_onEntitlementChanged);
  }

  /// Every state change goes through here.
  ///
  /// Almost all of this cubit's work is async — catalog fetches, a Play query,
  /// a verify round trip — and the user can leave the Billing page at any point
  /// during it. The cubit is then closed while those futures are still in
  /// flight, and the emit that follows throws "Cannot emit new states after
  /// calling close". Dropping the update is exactly right: nothing is listening.
  void _safeEmit(BillingState next) {
    if (isClosed) return;
    emit(next);
  }

  /// The entitlement just changed, so whatever the last purchase attempt said is
  /// no longer the current truth. Clearing here is what stops a dead error from
  /// sitting next to a plan card that already shows the new tier.
  void _onEntitlementChanged() => _safeEmit(_withEntitlement(state).copyWith(
        clearPurchaseError: true,
        clearPurchaseAlert: true,
      ));

  Future<void> load() async {
    // Recount seats/branches from local Drift so the usage meters are accurate
    // from the first paint — even offline, before any server sync.
    await _entitlement.recomputeLocalUsage();
    // Always render the current plan from the local entitlement cache first,
    // clearing any prior offline/failure flags for this fresh attempt.
    _safeEmit(_withEntitlement(state).copyWith(
      status: BillingStatus.ready,
      offline: false,
      catalogFailed: false,
      playSupported: _iap.isSupportedPlatform,
    ));

    final online = await _connectivity.isConnected;
    if (!online) {
      _safeEmit(state.copyWith(offline: true));
      return;
    }

    // Refresh the server entitlement (usage counts, status), then the catalog.
    try {
      await _entitlement.syncEntitlement();
      final plans = await _remoteDs.fetchPlans();
      final payments = await _remoteDs.fetchPayments();
      final devices = await _remoteDs.fetchDevices();
      _safeEmit(_withEntitlement(state).copyWith(
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
        // Ask Play what this account owns before the user can tap Upgrade. A
        // plan change needs that purchase as `oldPurchaseDetails`, and the only
        // other thing that populates it is a fire-and-forget call at startup —
        // so without this the first upgrade of a session can go out with a
        // stale or missing old purchase.
        //
        // Skipped once we already hold one, because a grant reloads the page and
        // a reload used to restore, which re-emitted the purchase and granted
        // again — a loop with a server round trip on every lap.
        if (_purchaseSync.activePurchase == null) {
          _pendingRestore =
              _purchaseSync.restore().catchError((Object e, StackTrace st) {
            debugPrint('[BillingCubit] restore on open failed: $e\n$st');
          });
          unawaited(_pendingRestore);
        }
      }
    } catch (e, st) {
      debugPrint('[BillingCubit] Error in load: $e\n$st');
      // Online but the catalog didn't load (schema not deployed / transient).
      // Keep the cached current plan; offer a Retry, not a false "offline".
      _safeEmit(_withEntitlement(state).copyWith(
        status: BillingStatus.ready,
        offline: false,
        catalogFailed: true,
      ));
    }
  }

  Future<void> refresh() => load();

  // ── Google Play purchase flow ───────────────────────────────────────────────

  /// Queries Play for live prices of the mapped SKUs and builds the offer list.
  /// Products Play doesn't return (not yet configured) are skipped, but the gap
  /// is reported rather than swallowed — a silently empty catalog is how "this
  /// plan isn't available right now" became a dead end with no explanation.
  Future<void> _loadPlayOffers() async {
    try {
      if (!await _iap.isAvailable()) {
        _safeEmit(state.copyWith(
          playOffers: const [],
          storeNotice: 'Google Play billing isn\'t available on this device '
              'right now. Check that the Play Store is installed, updated, and '
              'signed in.',
        ));
        return;
      }

      final mappings = await _remoteDs.fetchPlayProducts();
      if (mappings.isEmpty) {
        _safeEmit(state.copyWith(playOffers: const []));
        return;
      }
      final ids = mappings.map((m) => m.productId).toSet();
      final query = await _iap.queryProducts(ids);

      // Group by product id first: every offer of a product shares that id.
      final byProduct = <String, List<ProductDetails>>{};
      for (final d in query.products) {
        byProduct.putIfAbsent(d.id, () => []).add(d);
      }

      _detailsByOffer.clear();
      final offers = <PlayPlanOffer>[];
      for (final m in mappings) {
        final candidates = byProduct[m.productId];
        if (candidates == null || candidates.isEmpty) continue;
        final d = IapService.selectBasePlanOffer(candidates, m.basePlanId);
        if (d == null) continue;
        _detailsByOffer[_offerKey(m.productId, m.basePlanId)] = d;
        offers.add(PlayPlanOffer(
          planCode: m.planCode,
          billingPeriod: m.billingPeriod,
          productId: m.productId,
          basePlanId: m.basePlanId,
          priceLabel: d.price,
        ));
      }

      _safeEmit(state.copyWith(
        playOffers: offers,
        storeNotice: _storeNoticeFor(query, mappings.length, offers.length),
        clearStoreNotice:
            _storeNoticeFor(query, mappings.length, offers.length) == null,
      ));
    } catch (e, st) {
      debugPrint('[BillingCubit] Error in _loadPlayOffers: $e\n$st');
      _safeEmit(state.copyWith(
        storeNotice: 'Couldn\'t load plan prices from Google Play. Pull to '
            'refresh to try again.',
      ));
    }
  }

  /// Turns a partial Play catalog into something a human can act on. Null when
  /// everything resolved.
  String? _storeNoticeFor(IapProductQuery query, int expected, int resolved) {
    if (query.hasError) {
      return 'Google Play couldn\'t return plan prices (${query.error}). '
          'Pull to refresh to try again.';
    }
    if (query.notFoundIds.isNotEmpty || resolved < expected) {
      return 'Some plans aren\'t available for purchase yet. If this persists, '
          'contact support.';
    }
    return null;
  }

  /// Launch the Play purchase flow for [planCode] at [period]. The outcome
  /// arrives on the purchase stream, not from this call.
  ///
  /// If the tenant already owns a different active Play subscription, this is
  /// sent as a plan change (`oldPurchaseDetails`) so Play replaces it instead
  /// of stacking a second, separately-billed subscription.
  Future<void> buyPlan(String planCode, String period) async {
    if (!_iap.isSupportedPlatform) return;
    final offer = state.playOffers.firstWhereOrNull(
      (o) => o.planCode == planCode && o.billingPeriod == period,
    );
    final details =
        offer == null ? null : _detailsByOffer[_offerKey(offer.productId, offer.basePlanId)];
    if (offer == null || details == null) {
      _safeEmit(state.copyWith(
        purchaseError: state.storeNotice ??
            'This plan isn\'t available for purchase right now.',
      ));
      return;
    }
    _safeEmit(state.copyWith(
      purchaseInProgress: true,
      clearPurchaseError: true,
      clearPurchaseAlert: true,
    ));

    // Let the page-open restore land first. Play's answer is what supplies
    // `oldPurchaseDetails`, and buying without it stacks a second subscription
    // rather than replacing the current one.
    await _awaitPendingRestore();

    // Play's own view of what's owned — NOT the entitlement. The two disagree
    // whenever a purchase was made but never verified, and trusting the
    // entitlement there is what turned a plan change into a duplicate buy.
    final owned = _purchaseSync.activePurchase;

    // Already own exactly this product: Play would reject a second purchase with
    // ITEM_ALREADY_OWNED. What the user actually needs is the grant they never
    // got, so re-verify the token instead of opening a doomed purchase sheet.
    if (owned != null && owned.productID == details.id) {
      final recovered = await _purchaseSync.reverifyActive();
      _safeEmit(state.copyWith(
        purchaseInProgress: false,
        purchaseError: recovered
            ? null
            : 'You already own this plan on Google Play. We\'re restoring it — '
                'this can take a moment.',
        clearPurchaseError: recovered,
      ));
      return;
    }

    final launched = await _iap.buySubscription(
      details,
      accountId: _obfuscatedAccountId(),
      oldPurchase: owned,
      replacementMode: _replacementModeFor(planCode, period, owned),
    );
    if (!launched) {
      _safeEmit(state.copyWith(
        purchaseInProgress: false,
        purchaseError: 'Couldn\'t start the purchase. Please try again.',
      ));
    }
  }

  /// Wait for an in-flight restore, but never indefinitely — a Play Store that
  /// never answers must not leave Upgrade dead. Timing out is safe: the buy
  /// still goes ahead, just without a replacement target.
  Future<void> _awaitPendingRestore() async {
    final pending = _pendingRestore;
    if (pending == null) return;
    try {
      await pending.timeout(_restoreWait);
    } catch (e, st) {
      debugPrint('[BillingCubit] restore did not settle before buy: $e\n$st');
    } finally {
      _pendingRestore = null;
    }
  }

  /// How Play should bill the switch from [owned] to the target plan.
  ///
  /// Never `chargeProratedPrice`: Google only accepts it for an upgrade that
  /// keeps the SAME billing period, so a monthly→annual switch is rejected
  /// outright — which is what surfaced as "We are unable to change your
  /// subscription plan". `withTimeProration` credits the unused time and works
  /// across periods, so it is the safe immediate-switch mode.
  ReplacementMode _replacementModeFor(
    String targetPlanCode,
    String targetPeriod,
    PurchaseDetails? owned,
  ) {
    if (owned == null) return ReplacementMode.withTimeProration;
    // A period change is a different commitment, not a cheaper tier — switch now
    // and let Play credit the remainder rather than deferring for up to a year.
    final ownedPeriod = _periodOfProduct(owned.productID);
    if (ownedPeriod != null && ownedPeriod != targetPeriod) {
      return ReplacementMode.withTimeProration;
    }
    return _isDowngrade(targetPlanCode, targetPeriod)
        ? ReplacementMode.deferred
        : ReplacementMode.withTimeProration;
  }

  PlayPlanOffer? _offerOfProduct(String productId) =>
      state.playOffers.firstWhereOrNull((o) => o.productId == productId);

  String? _periodOfProduct(String productId) =>
      _offerOfProduct(productId)?.billingPeriod;

  /// True when the target costs less per year than what's currently owned — a
  /// downgrade defers to renewal so paid-for time isn't lost.
  ///
  /// Compares annualised prices, because comparing `priceMonthly` alone ignores
  /// the period toggle entirely and calls annual→monthly an "upgrade". The
  /// baseline comes from the product Play says is owned, not the entitlement:
  /// when a purchase hasn't been verified the entitlement still reads `free`,
  /// which would misprice every comparison against it.
  bool _isDowngrade(String targetPlanCode, String targetPeriod) {
    final ownedOffer =
        _offerOfProduct(_purchaseSync.activePurchase?.productID ?? '');
    final currentPlan = ownedOffer?.planCode ?? state.planCode;
    final currentPeriod = ownedOffer?.billingPeriod ?? 'monthly';
    final current = _annualisedPrice(currentPlan, currentPeriod);
    final target = _annualisedPrice(targetPlanCode, targetPeriod);
    if (current == null || target == null) return false;
    return target < current;
  }

  /// Annual plans bill 10 months' worth (2 free), matching the server's ledger.
  double? _annualisedPrice(String planCode, String period) {
    final monthly =
        state.plans.firstWhereOrNull((p) => p.code == planCode)?.priceMonthly;
    if (monthly == null) return null;
    return period == 'annual' ? monthly * 10 : monthly * 12;
  }

  /// Ask Play to re-emit what this account owns, so a reinstall or a second
  /// device recovers its plan. Verification happens in PlayPurchaseSyncService;
  /// this only drives the spinner.
  Future<void> restore() async {
    if (!_iap.isSupportedPlatform) return;
    _safeEmit(state.copyWith(purchaseInProgress: true, clearPurchaseError: true));
    try {
      await _purchaseSync.restore();
      // Restored items land on the event stream and settle the spinner there;
      // drop it now in case the account owns nothing to restore.
      _safeEmit(state.copyWith(purchaseInProgress: false));
    } catch (e, st) {
      debugPrint('[BillingCubit] Error in restore: $e\n$st');
      _safeEmit(state.copyWith(
        purchaseInProgress: false,
        purchaseError: 'Couldn\'t restore purchases. Please try again.',
      ));
    }
  }

  /// UI feedback only — the grant already happened (or didn't) in the service,
  /// and the plan itself repaints through [_onEntitlementChanged].
  void _onPurchaseEvent(PlayPurchaseEvent event) {
    switch (event.phase) {
      case PlayPurchasePhase.pending:
        _safeEmit(state.copyWith(purchaseInProgress: true, clearPurchaseError: true));
      case PlayPurchasePhase.granted:
        _safeEmit(state.copyWith(
          purchaseInProgress: false,
          clearPurchaseError: true,
          clearPurchaseAlert: true,
          // Set only when the grant landed but the local refresh didn't — the
          // plan IS active, so this is a notice, never an error.
          purchaseNotice: event.message,
        ));
        // Pull the catalog/history/devices too; the plan itself is already live.
        unawaited(load());
      case PlayPurchasePhase.superseded:
        // The old subscription of a plan change that already succeeded. Nothing
        // to tell the user — surfacing it is precisely the bug where a working
        // upgrade reported "we couldn't confirm your purchase".
        _safeEmit(state.copyWith(purchaseInProgress: false));
      case PlayPurchasePhase.canceled:
        // Backing out is not a failure, and a leftover error from the attempt
        // would otherwise sit on the page until the next state change.
        _safeEmit(state.copyWith(
          purchaseInProgress: false,
          clearPurchaseError: true,
          clearPurchaseAlert: true,
        ));
      case PlayPurchasePhase.failed:
        _safeEmit(state.copyWith(
          purchaseInProgress: false,
          purchaseError: event.message,
        ));
      case PlayPurchasePhase.stuck:
        // Charged but not granted — a snackbar is too easy to miss for
        // something the user paid for.
        _safeEmit(state.copyWith(
          purchaseInProgress: false,
          purchaseAlert: event.message,
        ));
    }
  }

  /// Ask the server to self-check its Play configuration.
  ///
  /// Costs nothing and involves no purchase, so it is the right first step for
  /// any "billing isn't working" report — previously the only way to learn that
  /// the setup was broken was for someone to be charged.
  Future<void> runConfigProbe() async {
    _safeEmit(state.copyWith(probeRunning: true, clearProbeError: true));
    try {
      final checks = await _remoteDs.probePlayConfig();
      _safeEmit(state.copyWith(probeRunning: false, probeChecks: checks));
    } catch (e, st) {
      debugPrint('[BillingCubit] Error in runConfigProbe: $e\n$st');
      _safeEmit(state.copyWith(
        probeRunning: false,
        probeChecks: const [],
        probeError: 'Couldn\'t reach the server to check your billing setup.',
      ));
    }
  }

  /// User acknowledged the stuck-purchase dialog.
  void dismissPurchaseAlert() =>
      _safeEmit(state.copyWith(clearPurchaseAlert: true));

  /// Retry from the stuck-purchase dialog.
  Future<void> retryStuckPurchase() async {
    _safeEmit(state.copyWith(clearPurchaseAlert: true, purchaseInProgress: true));
    final granted = await _purchaseSync.reverifyActive();
    if (!granted) {
      // reverifyActive emits its own failure event when it has a purchase to
      // work with; this covers the case where there is nothing cached at all.
      _safeEmit(state.copyWith(purchaseInProgress: false));
      await _purchaseSync.restore();
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
    // These mirror the entitlement exactly, so "the server no longer reports a
    // value" has to be able to erase the old one — a trial's daysRemaining must
    // not outlive the trial.
    return s.copyWith(
      overwriteEntitlementNulls: true,
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
    _purchaseEventSub?.cancel();
    _entitlement.entitlementRevision.removeListener(_onEntitlementChanged);
    return super.close();
  }
}
