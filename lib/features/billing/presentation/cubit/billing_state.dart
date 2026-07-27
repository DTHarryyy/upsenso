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
  final String effectiveStatus; // trialing|active|past_due|free|lapsed
  final bool cloudEnabled;
  final int? daysRemaining;
  final double? grandfatheredPrice;

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

  /// A Play purchase or restore is mid-flight — CTAs show a spinner/disable.
  final bool purchaseInProgress;

  /// Last purchase/restore failure, surfaced to the user then cleared.
  final String? purchaseError;

  const BillingState({
    this.status = BillingStatus.loading,
    this.errorMessage,
    this.planCode = 'free',
    this.effectiveStatus = 'free',
    this.cloudEnabled = false,
    this.daysRemaining,
    this.grandfatheredPrice,
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
    this.purchaseInProgress = false,
    this.purchaseError,
  });

  BillingState copyWith({
    BillingStatus? status,
    String? errorMessage,
    String? planCode,
    String? effectiveStatus,
    bool? cloudEnabled,
    int? daysRemaining,
    double? grandfatheredPrice,
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
    bool? purchaseInProgress,
    String? purchaseError,
    bool clearPurchaseError = false,
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
      purchaseInProgress: purchaseInProgress ?? this.purchaseInProgress,
      purchaseError:
          clearPurchaseError ? null : (purchaseError ?? this.purchaseError),
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
        purchaseInProgress,
        purchaseError,
      ];
}
