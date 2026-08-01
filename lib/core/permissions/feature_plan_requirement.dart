import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/entitlement_service.dart';

/// The lowest plan code that unlocks each plan-gated [AppFeature].
///
/// This mirrors the `feature_flags` column of `plan_limits` (currently
/// `20260731124330_plan_limits_retune.sql`) so the UI can name the tier a
/// merchant needs to buy. The server never sends "which tier would unlock
/// this" — only the flags for the tier you already hold — so the answer has to
/// live here.
///
/// Keep in sync with `plan_limits.feature_flags` whenever a flag moves between
/// tiers. Getting it wrong shows the wrong upsell; it can never grant access,
/// because [EntitlementService.featureAllowed] is still the gate.
String? requiredPlanFor(AppFeature feature) => switch (feature) {
  // crm: false → 'basic' at Starter.
  AppFeature.customerDirectory => 'starter',
  // procurement: false until Growth.
  AppFeature.procurement || AppFeature.supplierDirectory => 'growth',
  // audit: 'local' | 'cloud' | 'full' — the two surfaces sit on different
  // rungs. 'cloud' (Starter) makes the chain browsable; only 'full' (Growth)
  // adds the Unusual Activity dashboard.
  AppFeature.auditLogs => 'starter',
  AppFeature.fraudAlerts => 'growth',
  // Everything else is on every tier — nothing to upsell.
  _ => null,
};

/// The plan code to badge [feature] with in nav, or null when the current plan
/// already includes it.
///
/// Callers must have already cleared permission and the module gate: those two
/// mean "hide", this one means "show it locked". Mixing them up either leaks an
/// RBAC boundary into an upsell or paywalls a module the owner switched off
/// themselves.
String? planLockFor(AppFeature feature) {
  if (sl<EntitlementService>().featureAllowed(feature)) return null;
  return requiredPlanFor(feature);
}
