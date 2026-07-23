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
  }) {
    return BillingState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      planCode: planCode ?? this.planCode,
      effectiveStatus: effectiveStatus ?? this.effectiveStatus,
      cloudEnabled: cloudEnabled ?? this.cloudEnabled,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      grandfatheredPrice: grandfatheredPrice ?? this.grandfatheredPrice,
      branchUsage: branchUsage ?? this.branchUsage,
      seatUsage: seatUsage ?? this.seatUsage,
      deviceUsage: deviceUsage ?? this.deviceUsage,
      maxBranches: maxBranches ?? this.maxBranches,
      maxSeats: maxSeats ?? this.maxSeats,
      maxDevices: maxDevices ?? this.maxDevices,
      plans: plans ?? this.plans,
      payments: payments ?? this.payments,
      devices: devices ?? this.devices,
      offline: offline ?? this.offline,
      catalogFailed: catalogFailed ?? this.catalogFailed,
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
      ];
}
