// Simple DTOs for the billing feature. The authoritative *current* plan comes
// from EntitlementService; these back the catalog (plan picker), invoice list,
// and device list.

/// A purchasable plan tier + its resolved limits (from plans ⨝ plan_limits).
class PlanOption {
  final String code;
  final int version;
  final String name;
  final double priceMonthly;
  final bool isActive;
  final bool cloudEnabled;
  final int? maxBranches;
  final int? maxSeats;
  final int? maxDevices;
  final Map<String, dynamic> featureFlags;

  const PlanOption({
    required this.code,
    required this.version,
    required this.name,
    required this.priceMonthly,
    required this.isActive,
    required this.cloudEnabled,
    this.maxBranches,
    this.maxSeats,
    this.maxDevices,
    this.featureFlags = const {},
  });

  /// Annual = 10 months (2 free) per §5.1 — one rule, never stored.
  double get priceAnnual => priceMonthly * 10;
  double get perDay => priceMonthly / 30.0;
}

/// An à-la-carte add-on (device / branch / seat).
class PlanAddon {
  final String code;
  final String name;
  final double priceMonthly;
  final int unitQty;

  const PlanAddon({
    required this.code,
    required this.name,
    required this.priceMonthly,
    required this.unitQty,
  });
}

/// A row from billing_payments (invoice history).
class BillingPayment {
  final String id;
  final String kind; // plan | addon
  final double amount;
  final String currency;
  final String status; // pending | paid | failed | expired
  final bool isTest;
  final DateTime createdAt;
  final String? planCode;
  final String? addonCode;

  const BillingPayment({
    required this.id,
    required this.kind,
    required this.amount,
    required this.currency,
    required this.status,
    required this.isTest,
    required this.createdAt,
    this.planCode,
    this.addonCode,
  });
}

/// A registered device under the plan's device cap.
class RegisteredDevice {
  final String deviceUid;
  final String label;
  final String platform;
  final DateTime? registeredAt;
  final DateTime? lastSeenAt;
  final DateTime? revokedAt;

  const RegisteredDevice({
    required this.deviceUid,
    required this.label,
    required this.platform,
    this.registeredAt,
    this.lastSeenAt,
    this.revokedAt,
  });

  bool get isRevoked => revokedAt != null;
}
