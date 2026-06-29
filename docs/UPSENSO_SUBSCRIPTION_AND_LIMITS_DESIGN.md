# UPSENSO — Subscription, Plans & Limiting (Design)

> Status: **proposed** · Branch: `claude/platform-features-roadmap-7bqdgn`
> Detailed spec for Milestone **M7.1** of `docs/UPSENSO_PRODUCT_ROADMAP.md`.
> Covers: what we charge for, how limits are enforced (offline-first), the plan
> tiers, and the **pricing/yearly-discount math** — derived, not guessed.

## Design principles (fair-to-customer, offline-first)

These are hard constraints. Every decision below follows from them.

1. **A POS must never stop selling.** We never hard-cap core sale/refund/shift
   operations, and we never block them when the device is offline or billing
   can't be reached. Revenue-critical paths are always available.
2. **You always own your data.** Downgrade or lapse makes premium data
   **read-only**, never deleted. Export is available on every paid plan.
3. **Limit on value, not on survival.** We meter *structural* dimensions
   (branches, seats, advanced modules) — the things that scale with how much
   value the business gets — not on basic operation (number of receipts).
4. **Soft limits with warning + grace, not surprise cut-offs.** Approaching a
   limit warns; hitting it blocks only the *new* structural action (e.g. adding
   the 4th branch), never ongoing operations.
5. **Offline grace is generous and explicit.** Entitlement is cached locally;
   premium features keep working through a grace window before degrading. The
   user is told their status, never silently locked out.
6. **Transparent, predictable pricing.** Annual billing is a real discount with
   published math (below), not a vague "save more."

## What we meter (the value metric)

UPSENSO's value scales with the **size of the operation**, so we price on two
visible, fair dimensions plus capability tiers:

- **Branches** — multi-branch is the core architecture; more branches = more
  value and more sync/storage cost.
- **Seats** — an *active* (non-suspended) employee with login access. Suspended
  employees don't count (fair: you're not paying for people who can't use it).
- **Capabilities** — advanced modules/features (AI insights, full fraud engine,
  CRM/loyalty, accounting export, forecasting) gate by tier.

We deliberately do **NOT** meter: number of transactions, products, customers,
or audit log volume. Capping those would punish success and violate principle 1.

---

## Plan tiers

> Currency shown is **USD, illustrative**. Absolute amounts must be validated
> against the target market and infra COGS before launch (see "Pricing is
> derived, not absolute" below). The **structure, limits, and discount math are
> the deliverable** — the dollar figures are a defensible starting point.

| | **Free** | **Growth** | **Business** | **Enterprise** |
|---|---|---|---|---|
| Price (monthly) | $0 | $29 /mo | $79 /mo | Custom |
| Price (annual) | $0 | **$290 /yr** ($24.17/mo) | **$790 /yr** ($65.83/mo) | Custom |
| Branches | 1 | up to 3 | up to 10 | unlimited |
| Seats | 2 | 10 | 50 | unlimited |
| Extra seat (add-on) | — | $4 /seat/mo | $3 /seat/mo | negotiated |
| **Modules** | | | | |
| POS, Inventory, Expenses | ✅ | ✅ | ✅ | ✅ |
| Procurement, Suppliers, Recipes | — | ✅ | ✅ | ✅ |
| Reports + export | basic | ✅ full | ✅ full | ✅ full |
| Customers / CRM / Loyalty (M5) | — | basic | ✅ full | ✅ |
| **Intelligence** | | | | |
| AI assistant (NL queries) | — | ✅ | ✅ | ✅ |
| AI proactive insights (M2) | — | — | ✅ | ✅ |
| Demand forecasting (M3.3) | — | — | ✅ | ✅ |
| **Trust** | | | | |
| Audit log + integrity verify (M1.1) | view | ✅ | ✅ | ✅ |
| Fraud detection (M1.2) | — | basic rules | ✅ full engine | ✅ full |
| **Money** | | | | |
| Tax engine + accounting export (M6) | — | — | ✅ | ✅ |
| Budgets (M6.4) | — | — | ✅ | ✅ |
| **Platform** | | | | |
| Multi-currency (M7.2) | — | — | ✅ | ✅ |
| Priority support / SSO / SLA | — | — | — | ✅ |
| Data export | ✅ | ✅ | ✅ | ✅ |

**Free** exists to onboard a single-location shop with zero friction (and is a
fair forever-tier, not a crippled trial). **Growth** is the typical small
multi-branch business. **Business** unlocks the full "smart platform" promise
(proactive AI, full fraud, CRM, accounting). **Enterprise** is sales-led.

**14-day trial** of Business on signup (no card), then drops to Free unless
upgraded — data preserved, premium features become read-only.

---

## Pricing is derived, not absolute (the methodology)

The dollar figures above are produced by a repeatable method so they can be
re-derived for any market/currency rather than guessed:

1. **Anchor on value, ladder ~2.7×.** Each tier is roughly 2.5–3× the previous
   ($0 → $29 → $79 → custom). This is the standard SaaS "good/better/best"
   spread that keeps the middle tier the obvious choice.
2. **Per-active-seat sanity check.** Business at $79/mo for up to 50 seats ≈
   $1.58/seat at the cap, and ~$7.90/seat at a typical 10-seat shop — i.e. the
   buyer always pays well under the per-seat add-on rate, so the included bucket
   is genuinely a discount for committing to a tier (fair, not bait).
3. **Add-on priced below blended tier rate.** Extra seats cost *less* per seat at
   higher tiers ($4 → $3), rewarding scale instead of penalizing it.
4. **COGS floor (validate before launch).** Final numbers must clear
   per-tenant infra cost (Supabase rows/storage/egress + sync + support). The
   structure holds at any floor; only the absolute anchor moves.

> Action item before launch: replace the illustrative USD anchors with figures
> validated against (a) local market willingness-to-pay and (b) measured
> per-tenant COGS. The tier ratios, limits, and discount formula stay.

### Yearly discount — the calculation

We use the industry-standard, easy-to-communicate **"2 months free on annual."**
Customer pays for **10 months but gets 12**:

```
annual_price        = monthly_price × 10
effective_monthly   = annual_price / 12
discount_percentage = 1 − (annual_price / (monthly_price × 12))
                    = 1 − (10/12) = 16.667%
```

Applied:

| Plan | Monthly | ×12 (no discount) | Annual (×10) | Effective /mo | Customer saves |
|---|---|---|---|---|---|
| Growth | $29 | $348 | **$290** | $24.17 | **$58 /yr (16.67%)** |
| Business | $79 | $948 | **$790** | $65.83 | **$158 /yr (16.67%)** |

Add-on seats follow the same rule: `annual_seat = monthly_seat × 10`.

This is **fair and legible**: the customer can verify the saving themselves
("two months free"), and it's a real ~16.7% reduction — not a rounded marketing
number. The single `discount_months_free = 2` constant drives every annual
price, so changing the policy is a one-line change, never a table of hand-typed
prices that can drift.

**Proration & changes (fair rules):**
- **Upgrade mid-cycle:** charge the prorated difference for the remaining days.
- **Downgrade:** applies at period end (no clawback); premium data goes
  read-only, never deleted.
- **Annual → refund:** unused full months refundable within the period (configurable).
- **Add a branch/seat over plan:** offer in-product upgrade or per-unit add-on at
  the published rate — never a silent overage charge.

---

## Limiting & enforcement model

### Entitlement = the single source of truth

A business's effective capabilities are an **entitlement** resolved as:

```
effective_access(feature) =
      plan_entitlement(feature)        // does the plan include it?
  AND business_module_enabled(feature) // did the owner toggle it on?
  AND permission_service.can(...)      // does this employee have permission?
```

This **extends the existing two-layer gate** (module gate + permission matrix)
with a third, outermost layer: the plan. Order matters — plan is checked first
and cheapest. The existing `PermissionService.canAccessFeature()` becomes
`plan-aware` by consulting the cached entitlement before the module/permission
layers. **No existing permission logic changes** — we wrap it.

### Where each limit is enforced

| Limit | Enforced at |
|---|---|
| Module/feature availability | entitlement layer in `PermissionService` + GoRouter guard |
| Branch count | RLS on `branches` INSERT (`count < plan_limit`) **and** UI pre-check |
| Seat count | RLS on `employees` INSERT/reactivate **and** UI pre-check |
| Premium write actions | server-side RLS (`has_entitlement('fraud.full')` etc.) |
| Add-on seats | billing record adjusts the seat limit; same RLS check reads it |

**Security note (per `CLAUDE.md`):** UI hiding is UX only. Plan limits that
protect revenue/integrity are enforced **server-side in RLS** against the
authoritative subscription row, exactly like the existing permission RLS. The
local cache is for offline UX, never the source of truth for a write the server
can re-check.

### Offline-first entitlement (the hard part)

UPSENSO must work offline, but billing lives on the server. Resolution:

1. **Server is source of truth.** `subscriptions` + `plan_limits` live in
   Supabase. On each successful sync, the client caches a **signed/last-known-good
   entitlement snapshot** locally (read-only Drift table), with `valid_until`
   and a `grace_until`.
2. **Grace window.** If the device can't reach the server (offline, or a payment
   retry in progress), cached entitlement stays fully active until
   `grace_until` (default **14 days**, configurable; longer for annual plans).
   Plenty of slack for a shop that's offline for days.
3. **Degrade, never lock out.** After grace expires *and* the server has
   confirmed lapse on next sync: premium features become **read-only**, and the
   plan drops to **Free limits** — but **core POS/inventory/expenses keep
   working** (principle 1). The owner sees a clear "subscription needs attention"
   banner, never a dead app.
4. **Re-validate on reconnect.** First sync after reconnect refreshes the
   snapshot; a resumed/renewed plan restores access immediately.
5. **Clock-tamper resistance.** Grace is evaluated against the **last server
   sync timestamp**, not just device clock, so rolling the device clock forward
   doesn't extend grace.

### Usage metering (for limits + billing)

A lightweight `plan_usage` cache tracks current counts (branches, active seats)
so the UI can show "8 / 10 seats used" and warn before the limit. Counts are
derived from the real tables (source of truth) and reconciled on sync — the
cache is just for fast display + pre-checks.

---

## Schema

### Supabase (source of truth)

- `plans` — `code` (`free|growth|business|enterprise`), display name, monthly
  price, `is_active`. Reference data.
- `plan_limits` — `plan_code`, `max_branches`, `max_seats`, plus a JSONB
  `feature_flags` (e.g. `{"ai_insights":true,"fraud_full":true,...}`). Drives
  entitlement without code changes per plan tweak.
- `subscriptions` — `business_id` (PK/tenant), `plan_code`, `billing_period`
  (`monthly|annual`), `seat_addons` (int), `status`
  (`trialing|active|past_due|canceled`), `current_period_start/end`,
  `trial_end`, `grace_until`. **One per business.**
- `subscription_events` — append-only audit of plan changes (uses the M1
  hash-chain pattern; billing history must be tamper-evident too).

RLS: a business reads only its own subscription; **writes are service-role /
billing-webhook only** (clients never self-grant a plan). Limit-enforcing RLS on
`branches`/`employees` reads `plan_limits` ⨝ `subscriptions` for the tenant.

### Drift (local, read-only cache)

- `entitlement_cache` — `business_id`, `plan_code`, resolved `feature_flags`
  JSON, `max_branches`, `max_seats`, `seat_addons`, `valid_until`,
  `grace_until`, `last_server_sync_at`. Written only by the sync path.
- `plan_usage_cache` — `business_id`, `branch_count`, `active_seat_count`,
  `synced_at`.

Schema-version bump + additive migration both sides (per `CLAUDE.md` safety
rules; rollback = drop the two cache tables locally, drop billing tables +
policies on the server).

---

## Permissions & wiring (mandatory checklist)

- `PermissionKeys`: `billing.view`, `billing.manage`, `nav.billing`.
- `AppPermission`: `viewBilling`, `manageBilling`.
- `AppFeature`: `billingSubscription` → not module-gated (always reachable by an
  owner so a lapsed account can still pay), `navKey = 'nav.billing'`.
- Role matrix + default matrix: **Owner / Business Owner only** for
  `manageBilling`; `viewBilling` may extend to Branch Manager (read-only).
  Run `dart run tool/diff_matrices.dart`.
- New `EntitlementService` (`lib/core/permissions/entitlement_service.dart`)
  resolves the plan layer; `PermissionService.canAccessFeature()` consults it
  first. Registered in `di.dart`.
- New `billing` feature folder: plan picker, current usage ("8/10 seats"),
  upgrade/downgrade, invoice history, status banner widget (reused app-wide).

## Edge cases (explicitly handled)

- **Downgrade below current usage** (e.g. 5 branches → Growth's 3): existing
  branches keep operating; **no new branch** can be added until under limit.
  Nothing is deleted. Owner is told "you're over your new plan's limit."
- **Suspending vs deleting an employee:** suspending frees a seat immediately;
  reactivating re-checks the seat limit.
- **Trial expiry:** drops to Free, premium read-only, data intact.
- **Payment failure:** `past_due` keeps full access through `grace_until`, with
  escalating in-app banners; only then degrade.
- **Multi-device offline:** every device caches its own snapshot; the most recent
  `last_server_sync_at` wins on reconcile.

## Tests (critical paths)

- Entitlement resolution: plan ∩ module ∩ permission for each feature/tier.
- Limit enforcement: branch/seat INSERT blocked at limit (RLS + UI pre-check);
  add-on raises the limit.
- Pricing math: `annual = monthly × 10`, `discount = 16.667%`, proration on
  upgrade, no clawback on downgrade.
- Offline grace: full access within grace; degrade after grace + confirmed
  lapse; core POS never blocked; clock-tamper doesn't extend grace.
- Read-only-not-deleted on lapse/downgrade; restore on renewal.
- `subscription_events` hash chain verifies (reuses M1 verifier).
```
