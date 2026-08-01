import 'package:pos/features/billing/domain/billing_models.dart';

/// Tier arithmetic over a plan catalog. Kept apart from `plan_benefits.dart`,
/// which answers "what does this tier give you" rather than "where does it sit".

PlanOption? planOfCode(List<PlanOption> plans, String code) {
  for (final p in plans) {
    if (p.code == code) return p;
  }
  return null;
}

/// The tiers a tenant on [current] could move up to, cheapest first.
///
/// Excluding by code as well as price is deliberate: `fetchPlans` returns every
/// active row without deduping, so two live versions of one code can both be
/// present — and a price-only filter would then offer someone their own tier.
List<PlanOption> tiersAbove(List<PlanOption> plans, PlanOption current) {
  // The catalog arrives sorted ascending by price, so no re-sort here.
  return plans
      .where((p) => p.code != current.code && p.priceMonthly > current.priceMonthly)
      .toList();
}
