# UPSENSO — Subscription, Plans & Limiting (Design)

> Status: **proposed** · Branch: `claude/platform-features-roadmap-7bqdgn`
> Detailed spec for Milestone **M7.1** of `docs/UPSENSO_PRODUCT_ROADMAP.md`.
> This document is both the **plan** and the **scope/goals reference** for
> subscriptions: what we charge for, the plan limits, the PHP pricing (derived,
> not guessed), and — the hard part — **how limits are enforced fairly in an
> offline-first, multi-device system**.

---

## 1. Goals & scope

**Goal.** Monetize UPSENSO as a tiered SaaS for Philippine SMBs **without ever**
breaking the offline-first promise or treating paying customers unfairly.

**In scope (M7.1):** plans, limits (branches, seats, devices, products,
capabilities), PHP pricing + annual discount, entitlement resolution, **offline
+ multi-device limit enforcement and reconciliation**, schema, permission wiring,
edge cases, tests.

**Out of scope (later):** payment-gateway integration specifics (GCash/Maya/card
processor), dunning email content, tax invoicing/BIR receipt format for the
subscription itself, and the optional quota-leasing hardening (Section 6.4 —
documented, not built in v1).

---

## 2. Design principles (fair-to-customer, offline-first)

Hard constraints. Every decision below follows from them.

1. **A POS must never stop selling.** Core sale/refund/shift operations are never
   capped or billing-gated, even offline or when billing is unreachable.
2. **Never destroy user data to enforce a limit.** Hitting a limit blocks the
   *next* create; it never deletes, rejects, or loses what was already made.
3. **Limit on value, not survival.** We meter structural dimensions (branches,
   seats, devices, catalog size, advanced modules) — never the number of
   receipts.
4. **Soft limits with warning + grace, not surprise cut-offs.**
5. **The server is the only authority; clients are optimistic.** Offline, a
   device enforces its *best local estimate*. The server reconciles the true
   total on sync and has the final say — securely, so a tampered client can't win.
6. **Transparent PHP pricing** with a published, verifiable annual discount.

---

## 3. What we meter (the value metric)

Priced/limited dimensions — all fair, all visible:

- **Branches** — multi-branch is the core architecture.
- **Seats** — an *active* (non-suspended) employee with login. Suspended
  employees don't count.
- **Registered devices** — installs bound to the account. **Capping devices is
  also the primary defense that bounds offline-overshoot** (Section 6).
- **Products** — catalog size (the limit in the scenario this doc must solve).
- **Capabilities** — AI insights, full fraud engine, CRM/loyalty, accounting,
  forecasting — gated by tier.

We deliberately do **not** meter transactions, customers, or audit volume —
capping those would punish success and break Principle 1.

---

## 4. Plan tiers & PHP pricing

Currency: **Philippine Peso (₱)**. These are tuned for PH SMB willingness-to-pay
(typical local POS SaaS sits ~₱500–₱2,000/mo); validate against measured
per-tenant COGS before launch (Section 5).

| | **Free** | **Growth** | **Business** | **Enterprise** |
|---|---|---|---|---|
| **Monthly** | ₱0 | **₱499 /mo** | **₱1,299 /mo** | Custom |
| **Annual** | ₱0 | **₱4,990 /yr** (₱415.83/mo) | **₱12,990 /yr** (₱1,082.50/mo) | Custom |
| Branches | 1 | 3 | 10 | unlimited |
| Seats | 2 | 10 | 50 | unlimited |
| **Devices** | **2** | 10 | 50 | unlimited |
| **Products** | **100** | 2,000 | 20,000 | unlimited |
| Extra seat add-on | — | ₱99 /seat/mo | ₱79 /seat/mo | negotiated |
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
| Fraud detection (M1.2) | — | basic rules | ✅ full engine | ✅ |
| **Money** | | | | |
| Tax engine + accounting export (M6) | — | — | ✅ | ✅ |
| Budgets (M6.4) | — | — | ✅ | ✅ |
| **Platform** | | | | |
| Multi-currency (M7.2) | — | — | ✅ | ✅ |
| Priority support / SSO / SLA | — | — | — | ✅ |
| Data export | ✅ | ✅ | ✅ | ✅ |

**Free** is a genuine forever-tier for a single-location micro-shop (1 branch,
2 seats, 2 devices, 100 products) — enough to run a small store, not a crippled
trial. **Growth** = a typical small multi-branch SMB. **Business** = the full
"smart platform" (proactive AI, full fraud, CRM, accounting). **Enterprise** =
sales-led. **14-day Business trial** on signup (no card) → drops to Free with
data preserved (premium becomes read-only).

---

## 5. Pricing is derived, not guessed

A repeatable method so figures can be re-derived for any market:

1. **Value ladder ~2.6×.** ₱0 → ₱499 → ₱1,299 → custom keeps the middle tier the
   obvious pick (standard good/better/best spread).
2. **Per-active-seat sanity.** Business ₱1,299/mo for up to 50 seats ≈ ₱26/seat
   at the cap; for a typical 10-seat shop ≈ ₱130/seat — always **below** the
   ₱79–₱99 add-on rate, so an included bucket genuinely rewards committing to a
   tier (fair, not bait).
3. **Add-on below blended rate, cheaper at scale** (₱99 → ₱79) — rewards growth.
4. **COGS floor (validate before launch).** Final numbers must clear measured
   per-tenant infra cost (Supabase rows/storage/egress + sync + support). Only
   the absolute anchor moves; the ratios, limits, and discount formula stay.

### 5.1 Yearly discount — calculated, not invented

Industry-standard, legible **"2 months free on annual"**: pay for 10 months, get
12.

```
annual_price        = monthly_price × 10
effective_monthly   = annual_price / 12
discount_percentage = 1 − (annual_price / (monthl3   y_price × 12))
                    = 1 − (10/12) = 16.667%
```

| Plan | Monthly | ×12 (no discount) | Annual (×10) | Effective /mo | Customer saves |
|---|---|---|---|---|---|
| Growth | ₱499 | ₱5,988 | **₱4,990** | ₱415.83 | **₱998 /yr (16.67%)** |
| Business | ₱1,299 | ₱15,588 | **₱12,990** | ₱1,082.50 | **₱2,598 /yr (16.67%)** |

A single `discount_months_free = 2` constant drives every annual price (and
annual add-ons: `annual_seat = monthly_seat × 10`), so prices can never drift.
Customers can verify the saving themselves ("two months free") — a real ~16.7%,
not a rounded marketing number.

**Proration (fair rules):** upgrade mid-cycle = prorated difference; downgrade =
at period end, premium data read-only, never deleted; annual unused months
refundable within the period (configurable).

---

## 6. Offline-first limit enforcement (the hard part)

This section answers: *Free plan, product limit = 100, 10 devices offline, each
creates 100 → 1,000 products on reconnect. What happens?*

### 6.1 Why a hard limit is impossible offline (state it plainly)

Enforcing "≤ 100 products total" is a **global invariant**. A global invariant
needs a single authority that sees every write *at write time*. Offline-first, by
definition, accepts writes with **no coordination**. You cannot have both. So the
honest options are only:

- **(A) Prevent offline creation near the limit** — block creates whenever the
  device can't confirm the global count with the server. Strict, but **terrible
  UX** (your POS won't let you add a product because the wifi is down) and it
  breaks the offline promise. **Rejected.**
- **(B) Allow optimistic offline creation, reconcile on the server, never lose
  data.** Slightly over-allows in rare multi-device bursts, but UX stays great
  and the server still ends up authoritative. **Chosen.**

We choose **(B)** and make the overage harmless and self-correcting.

### 6.2 The model — three layers

**Layer 1 — Edge (device): optimistic soft check.**
Each device knows `effectiveCount = serverConfirmedCount + localPendingCreates −
localPendingDeletes` from its last sync + its own queue. On create:
- `effectiveCount < limit` → allow silently.
- `limit ≤ effectiveCount < limit + buffer` → allow **with a warning** ("You're
  near your 100-product limit"). The **buffer** (default = `max(10, 10%)`)
  absorbs the honest single-device boundary case so nobody is blocked by one
  product offline.
- `effectiveCount ≥ limit + buffer` → block locally with an upgrade prompt.

This handles the **common case** (one device, or devices that have synced
recently) immediately and correctly. It cannot, by itself, stop *independent*
offline devices from each believing they're under the limit — that's Layer 2's job.

**Layer 2 — Server: authoritative reconciliation on sync.**
When a device syncs, the server recomputes the true `count(products WHERE
business_id = ? AND deleted_at IS NULL)`. It **accepts every synced row** (never
rejects — Principle 2). Then:
- `total ≤ limit` → nothing to do.
- `total > limit` → set account flag `products.over_limit = true`, record
  `overage = total − limit`, and put a **soft lock** on *new* product creation:
  the next entitlement snapshot every device pulls carries
  `creation_locked.products = true`.

Result of the scenario: all 1,000 products **persist and are fully usable** (you
can sell every one of them). The account simply enters an **over-limit state**:
no *new* products can be created on any device until the owner either:
1. **upgrades** (e.g. Growth lifts the cap to 2,000 → instantly unlocked), or
2. **archives/deletes** products back to ≤ 100.

Existing operations — selling, editing, refunding, inventory — are untouched.
This is the fair resolution: the business keeps all its work and is nudged, not
punished.

**Layer 3 — Bounding the blast radius (security/abuse, see 6.3 & 6.4).**
Device caps make the 10-device scenario impossible on Free in the first place,
and optional quota leasing can eliminate overshoot entirely for tiers that need
a hard cap.

### 6.3 Why this is secure (a tampered client can't win)

- **The count is recomputed server-side**, from the actual rows, under RLS. A
  client can lie about its local estimate, but it cannot make the server's
  `COUNT(*)` smaller. Overage is always detected on sync.
- **Entitlement is server-signed and client-read-only.** A device can't grant
  itself a higher limit; `plan_limits` ⨝ `subscriptions` is the source of truth.
- **The 10-device attack is bounded by the device cap.** Free allows **2
  registered devices**. A 3rd device can register only while **online**, at which
  point the server already sees the current total and refuses to lift the cap.
  So worst-case offline overshoot on Free ≈ `2 devices × (limit + buffer)` ≈ 220,
  not 1,000 — and even that collapses back to a soft lock on reconcile, gaining
  the abuser **nothing durable**: they can't keep creating, and they're prompted
  to upgrade. The exploit yields a one-time, non-renewable over-allowance with no
  ongoing benefit, so there's no incentive to pursue it.
- **Reconciliation is logged** to `subscription_events` (hash-chained, reusing
  M1) so overage handling is auditable.

### 6.4 Optional hardening — quota leasing (documented, not in v1)

For tiers/resources that ever need a *true* hard cap, the server can **lease**
quota to devices while online: device requests N slots, server reserves them
against the global limit, device may create up to N offline; unused slots expire
back to the pool on next sync. This makes overshoot mathematically impossible at
the cost of needing periodic online check-ins (a device with an exhausted lease
can't create while offline). **Default off** — soft-cap + reconcile is better UX
for SMBs. We keep the schema lease-compatible so this can be switched on per
plan later without migration churn.

### 6.5 What the user sees (UX summary)

| Situation | Experience |
|---|---|
| Under limit | Nothing — silent. |
| Within buffer, offline | Gentle "approaching your limit" hint; creation still works. |
| Over buffer, offline | Block new creates + "Upgrade to add more products"; everything else works. |
| Reconnect → server finds overage | Banner: "You have 1,000 / 100 products. Upgrade or archive to add more." No data lost; selling unaffected. |
| Upgrade | Cap lifts, lock clears on next sync — instantly. |
| Downgrade below current count | Existing kept & usable; can't add new until under the new cap. |

---

## 7. Entitlement = the gate (extends the existing two layers)

A business's effective access is resolved as a **third, outermost layer** over
the current module + permission gates:

```
effective_access(feature) =
      plan_entitlement(feature)        // plan includes it AND not creation_locked
  AND business_module_enabled(feature) // owner toggled it on
  AND permission_service.can(...)      // employee has permission
```

`PermissionService.canAccessFeature()` consults a new plan-aware
`EntitlementService` first (cheapest check). **No existing permission logic
changes** — we wrap it. Count-limits (products/branches/seats/devices) are
checked by `EntitlementService.canCreate(resource)` against the cached limit +
local count, and enforced for real in RLS server-side.

### Where each limit is enforced

| Limit | Enforced at |
|---|---|
| Module/feature availability | `EntitlementService` + GoRouter guard |
| Product count | edge soft-check (Layer 1) + **server reconcile** (Layer 2) |
| Branch / seat count | RLS on INSERT (`count < limit`) + UI pre-check |
| Device count | server device-registration (online-only) + RLS |
| Premium write actions | server-side RLS (`has_entitlement(...)`) |

**Security note (per `CLAUDE.md`):** UI hiding is UX only. Revenue/integrity
limits are enforced **server-side in RLS** against the authoritative subscription
row; the local cache is for offline UX, never the source of truth for a write the
server can re-check.

### Offline entitlement grace (for *feature* access, distinct from counts)

Entitlement snapshots are cached locally (read-only) with `valid_until` /
`grace_until`. If billing is unreachable, premium **features** stay active until
`grace_until` (default **14 days**, longer for annual). After grace **and** a
server-confirmed lapse, premium features degrade to **read-only** and limits drop
to Free — but **core POS/inventory/expenses keep working**. Grace is measured
against **last server-sync time**, not device clock (clock-tamper resistant).

---

## 8. Schema

### Supabase (source of truth)

- `plans` — `code` (`free|growth|business|enterprise`), name, `price_monthly`
  (₱), `is_active`.
- `plan_limits` — `plan_code`, `max_branches`, `max_seats`, `max_devices`,
  `max_products`, JSONB `feature_flags` (`{"ai_insights":true,...}`). Drives
  entitlement without code changes per tweak.
- `subscriptions` — `business_id` (PK/tenant), `plan_code`, `billing_period`
  (`monthly|annual`), `seat_addons`, `status`
  (`trialing|active|past_due|canceled`), `current_period_start/end`,
  `trial_end`, `grace_until`. One per business.
- `account_limit_state` — `business_id`, per-resource `over_limit` bool +
  `overage` int + `creation_locked` bool (set by reconciliation, read into the
  client entitlement snapshot).
- `devices` — `id`, `business_id`, `label`, `registered_at`, `last_seen_at`,
  `revoked_at`. Registration is **online-only**; enforces `max_devices`.
- `subscription_events` — append-only, **hash-chained (reuses M1)**: plan
  changes, overage detections, lock/unlock. Billing history must be
  tamper-evident too.
- (lease-ready, off by default) `quota_leases` — `device_id`, `resource`,
  `granted`, `used`, `expires_at`.

RLS: a business reads only its own rows; **subscription/limit writes are
service-role / billing-webhook only** (clients never self-grant). Limit-enforcing
RLS on `branches`/`employees`/`products` reads `plan_limits` ⨝ `subscriptions`
for the tenant. The product-count RLS is the **reconciliation authority** — it
also runs the over-limit flagging via a trigger/function on sync.

### Drift (local, read-only cache — written only by the sync path)

- `entitlement_cache` — `business_id`, `plan_code`, `feature_flags` JSON,
  `max_branches`, `max_seats`, `max_devices`, `max_products`, `seat_addons`,
  `valid_until`, `grace_until`, `last_server_sync_at`,
  `creation_locked_json` (per-resource).
- `resource_usage_cache` — `business_id`, `branch_count`, `active_seat_count`,
  `device_count`, `product_count`, `synced_at` (drives "82 / 100 products" UI +
  Layer-1 soft checks).

Schema-version bump + additive migration both sides (per `CLAUDE.md`; rollback =
drop the cache tables locally, drop billing tables + policies on the server).

---

## 9. Permissions & wiring (mandatory checklist)

- `PermissionKeys`: `billing.view`, `billing.manage`, `nav.billing`.
- `AppPermission`: `viewBilling`, `manageBilling`.
- `AppFeature`: `billingSubscription` → **not** module-gated (an owner must reach
  billing even on a lapsed account), `navKey = 'nav.billing'`.
- Role + default matrices: `manageBilling` = **Owner / Business Owner only**;
  `viewBilling` may extend to Branch Manager (read-only). Run
  `dart run tool/diff_matrices.dart`.
- New `EntitlementService` (`lib/core/permissions/entitlement_service.dart`);
  `PermissionService` consults it first; registered in `di.dart`.
- New `billing` feature folder: plan picker, **usage meters** ("82/100 products",
  "8/10 seats"), upgrade/downgrade, invoice history, and a reusable
  account-status / over-limit banner widget.

---

## 10. Edge cases (explicitly handled)

- **Multi-device offline overshoot** — Section 6: accept all, soft-lock new
  creates, never lose data, bounded by device cap.
- **Downgrade below current usage** (5 branches → Growth's 3, or 1,000 → 100
  products): existing kept & operational; no *new* of that resource until under
  the cap; nothing deleted.
- **Suspend vs delete employee:** suspending frees a seat immediately;
  reactivating re-checks the seat limit.
- **Device registration while offline:** not allowed — registration needs the
  server (this is what bounds overshoot). An unregistered install can operate in
  read-only/guest until it can register.
- **Trial expiry / payment failure:** `past_due` keeps full access through
  `grace_until` with escalating banners; only then degrade.
- **Clock tampering:** grace + lease expiry keyed off last server-sync time.

---

## 11. Tests (critical paths)

- Entitlement resolution: plan ∩ module ∩ permission for each feature/tier.
- **Offline limit (the scenario):** N devices each create up to limit offline →
  on reconcile, all rows persist, account flips `over_limit`, `creation_locked`
  set, no data lost; upgrade clears the lock; archive back under cap clears it.
- Edge soft-check: warns within buffer, blocks past `limit + buffer`, uses
  `serverConfirmedCount + localPending`.
- Device cap bounds overshoot; 3rd device can't register offline.
- Limit RLS: branch/seat/product INSERT blocked at cap server-side even if a
  client bypasses the UI; reconciliation trigger flags overage correctly.
- Pricing math: `annual = monthly × 10`, `discount = 16.667%`, proration on
  upgrade, no clawback on downgrade.
- Offline grace: full access within grace; degrade after grace + confirmed lapse;
  core POS never blocked; clock-tamper doesn't extend grace.
- Read-only-not-deleted on lapse/downgrade; restore on renewal.
- `subscription_events` hash chain verifies (reuses M1 verifier).
```
