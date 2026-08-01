import 'package:equatable/equatable.dart';

import 'package:pos/features/billing/domain/billing_models.dart';

enum BillingStatus { loading, ready, error }

/// Snapshot of the current plan, sourced from EntitlementService (offline-safe),
/// plus the remotely-fetched catalog/history. The current-plan card + usage
/// meters render from the entitlement fields even with no network.
class BillingState extends Equatable {
  final BillingStatus status;
  final String? errorMessage;

  // Current plan (from EntitlementService cache).
  final String planCode;
  final String effectiveStatus; // trialing|active|unverified|past_due|free|lapsed
  final bool cloudEnabled;
  final int? daysRemaining;
  final double? grandfatheredPrice;

  /// monthly | annual, null on Free — the summary card omits the period suffix
  /// rather than assuming monthly.
  final String? billingPeriod;

  /// End of the paid period; the date the plan next renews.
  final DateTime? renewsOn;

  // Usage vs cap (null cap = unlimited/unknown).
  final int branchUsage;
  final int seatUsage;
  final int deviceUsage;
  final int? maxBranches;
  final int? maxSeats;
  final int? maxDevices;

  // Remote catalog + history (empty offline).
  final List<PlanOption> plans;
  final List<BillingPayment> payments;
  final List<RegisteredDevice> devices;

  /// Device has no connection — current plan renders from cache, changes are
  /// disabled with a calm "you're offline" note.
  final bool offline;

  /// Online, but the catalog/entitlement fetch failed (e.g. billing schema not
  /// deployed, transient server error). Distinct from [offline] so the UI can
  /// offer a Retry instead of misleadingly saying "offline".
  final bool catalogFailed;

  /// This platform can buy via Google Play (Android with the store available).
  /// False on web/desktop, where the page is read-only and points to Android.
  final bool playSupported;

  /// Purchasable Play offers (plan + period + store price), resolved from
  /// `play_product_map` ⨝ live Play prices. Empty until Play is configured.
  final List<PlayPlanOffer> playOffers;

  /// The Play product this device knows the tenant owns — narrows the "Manage
  /// subscription" deep link to the exact subscription.
  final String? ownedProductId;

  /// A Play purchase is mid-flight — CTAs show a spinner/disable.
  final bool purchaseInProgress;

  /// An automatic restore is talking to Play. Separate from
  /// [purchaseInProgress] because restore now runs on its own (there is no
  /// button), and silent background work on a billing page reads as a hang.
  final bool restoreInProgress;

  /// Last purchase/restore failure, surfaced to the user then cleared.
  final String? purchaseError;

  /// Play's catalog is reachable but incomplete (a SKU isn't live yet, or the
  /// query errored). Shown as a calm inline note rather than only failing at the
  /// moment the user taps Upgrade.
  final String? storeNotice;

  /// A purchase that was CHARGED but not granted. This gets a blocking dialog
  /// with a Retry, never a snackbar — money is involved and a snackbar is
  /// missable.
  final String? purchaseAlert;

  /// Good news that still needs saying — a grant that landed on the server while
  /// this device's refresh didn't. Reads as a neutral note, never an error,
  /// because the plan really is active.
  final String? purchaseNotice;

  const BillingState({
    this.status = BillingStatus.loading,
    this.errorMessage,
    this.planCode = 'free',
    this.effectiveStatus = 'free',
    this.cloudEnabled = false,
    this.daysRemaining,
    this.grandfatheredPrice,
    this.billingPeriod,
    this.renewsOn,
    this.branchUsage = 0,
    this.seatUsage = 0,
    this.deviceUsage = 0,
    this.maxBranches,
    this.maxSeats,
    this.maxDevices,
    this.plans = const [],
    this.payments = const [],
    this.devices = const [],
    this.offline = false,
    this.catalogFailed = false,
    this.playSupported = false,
    this.playOffers = const [],
    this.ownedProductId,
    this.purchaseInProgress = false,
    this.restoreInProgress = false,
    this.purchaseError,
    this.storeNotice,
    this.purchaseAlert,
    this.purchaseNotice,
  });

  BillingState copyWith({
    BillingStatus? status,
    String? errorMessage,
    String? planCode,
    String? effectiveStatus,
    bool? cloudEnabled,
    int? daysRemaining,
    double? grandfatheredPrice,
    String? billingPeriod,
    DateTime? renewsOn,
    int? branchUsage,
    int? seatUsage,
    int? deviceUsage,
    int? maxBranches,
    int? maxSeats,
    int? maxDevices,
    List<PlanOption>? plans,
    List<BillingPayment>? payments,
    List<RegisteredDevice>? devices,
    bool? offline,
    bool? catalogFailed,
    bool? playSupported,
    List<PlayPlanOffer>? playOffers,
    String? ownedProductId,
    bool? purchaseInProgress,
    bool? restoreInProgress,
    String? purchaseError,
    String? storeNotice,
    String? purchaseAlert,
    String? purchaseNotice,
    bool clearOwnedProductId = false,
    bool clearPurchaseError = false,
    bool clearStoreNotice = false,
    bool clearPurchaseAlert = false,
    bool clearPurchaseNotice = false,
    // Marks this call as authoritative for the nullable entitlement fields:
    // they are taken verbatim, null included. Without it `x ?? this.x` can only
    // ever SET a value, so a trial→active transition would keep showing the
    // trial's "2 days left" forever.
    bool overwriteEntitlementNulls = false,
  }) {
    return BillingState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      planCode: planCode ?? this.planCode,
      effectiveStatus: effectiveStatus ?? this.effectiveStatus,
      cloudEnabled: cloudEnabled ?? this.cloudEnabled,
      daysRemaining: overwriteEntitlementNulls
          ? daysRemaining
          : (daysRemaining ?? this.daysRemaining),
      grandfatheredPrice: overwriteEntitlementNulls
          ? grandfatheredPrice
          : (grandfatheredPrice ?? this.grandfatheredPrice),
      billingPeriod: overwriteEntitlementNulls
          ? billingPeriod
          : (billingPeriod ?? this.billingPeriod),
      renewsOn:
          overwriteEntitlementNulls ? renewsOn : (renewsOn ?? this.renewsOn),
      branchUsage: branchUsage ?? this.branchUsage,
      seatUsage: seatUsage ?? this.seatUsage,
      deviceUsage: deviceUsage ?? this.deviceUsage,
      maxBranches: overwriteEntitlementNulls
          ? maxBranches
          : (maxBranches ?? this.maxBranches),
      maxSeats:
          overwriteEntitlementNulls ? maxSeats : (maxSeats ?? this.maxSeats),
      maxDevices: overwriteEntitlementNulls
          ? maxDevices
          : (maxDevices ?? this.maxDevices),
      plans: plans ?? this.plans,
      payments: payments ?? this.payments,
      devices: devices ?? this.devices,
      offline: offline ?? this.offline,
      catalogFailed: catalogFailed ?? this.catalogFailed,
      playSupported: playSupported ?? this.playSupported,
      playOffers: playOffers ?? this.playOffers,
      ownedProductId: clearOwnedProductId
          ? null
          : (ownedProductId ?? this.ownedProductId),
      purchaseInProgress: purchaseInProgress ?? this.purchaseInProgress,
      restoreInProgress: restoreInProgress ?? this.restoreInProgress,
      purchaseError:
          clearPurchaseError ? null : (purchaseError ?? this.purchaseError),
      storeNotice:
          clearStoreNotice ? null : (storeNotice ?? this.storeNotice),
      purchaseAlert:
          clearPurchaseAlert ? null : (purchaseAlert ?? this.purchaseAlert),
      // Never sticky: a notice describes one moment, so it must not survive the
      // next state change the way an unresolved error legitimately does.
      purchaseNotice: clearPurchaseNotice ? null : purchaseNotice,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        planCode,
        effectiveStatus,
        cloudEnabled,
        daysRemaining,
        grandfatheredPrice,
        billingPeriod,
        renewsOn,
        branchUsage,
        seatUsage,
        deviceUsage,
        maxBranches,
        maxSeats,
        maxDevices,
        plans,
        payments,
        devices,
        offline,
        catalogFailed,
        playSupported,
        playOffers,
        ownedProductId,
        purchaseInProgress,
        restoreInProgress,
        purchaseError,
        storeNotice,
        purchaseAlert,
        purchaseNotice,
      ];
}
