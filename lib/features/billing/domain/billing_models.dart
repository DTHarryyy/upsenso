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

/// A row from `play_product_map` — which Play SKU maps to which plan + period.
/// The Play product ids live only server-side; the client reads them here and
/// never hardcodes them.
class PlayProductMapping {
  final String productId;
  final String basePlanId;
  final String planCode;
  final int planVersion;
  final String billingPeriod; // monthly | annual

  const PlayProductMapping({
    required this.productId,
    required this.basePlanId,
    required this.planCode,
    required this.planVersion,
    required this.billingPeriod,
  });
}

/// A purchasable Play offer resolved for the UI: a plan + period bound to a Play
/// product id with its store-localized price. Display-only — the plugin's
/// `ProductDetails` handle stays inside the cubit, off the equatable state.
class PlayPlanOffer {
  final String planCode;
  final String billingPeriod; // monthly | annual
  final String productId;
  final String basePlanId;
  final String priceLabel; // localized, straight from Play

  const PlayPlanOffer({
    required this.planCode,
    required this.billingPeriod,
    required this.productId,
    required this.basePlanId,
    required this.priceLabel,
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
