# UPSENSO — Subscription, Plans & Limiting (Design)

> Status: **proposed (v3 — 3-tier launch + trust-safe scaling, 2026-07-06;
> supersedes v2 local-vs-cloud model)** · Spec for
> Milestone **M7.1** of `docs/UPSENSO_PRODUCT_ROADMAP.md`.
> This document is both the **plan** and the **scope/goals reference** for
> subscriptions: what we charge for, the plan limits, the PHP pricing (derived,
> not guessed), and how limits are enforced fairly in an offline-first system.
>
> **v2 change (the core idea):** the paywall is **the cloud**, not product
> counts. **Free = a fully-functional local POS on one device (unlimited
> records, ~₱0 cost to us).** The first thing you ever pay for is cloud sync +
> backup + multi-device. This is cheaper to run, fairer, more affordable for
> Philippine micro-SMBs, and it *dissolves* the hardest problem in v1 (the
> multi-device offline product-overshoot scenario — see §6).
>
> **v3 change:** launch narrows to **3 tiers — Free / Starter ₱199 / Growth ₱499
> (full access)** — with **no Business/Enterprise at launch** (added later when
> M6/M7.2 ship, as a *new* tier on top). Structural growth is sold via
> **à-la-carte add-ons** (device/branch/seat), and all pricing is
> **grandfathered + plan-versioned** so we can iterate on price and packaging for
> years without ever making an existing customer worse off (see §4.9).

---

## 1. Goals & scope

**Goal.** Monetize UPSENSO as a tiered SaaS for Philippine SMBs **without ever**
breaking the offline-first promise or treating paying customers unfairly — and
with a genuinely affordable entry price for the huge micro-business segment
(sari-sari stores, carinderias, stalls) that competitors like Loyverse serve for
free.

**In scope (M7.1):** the local-vs-cloud plan model, PHP pricing + annual
discount, entitlement resolution, **gating the sync layer by entitlement**, the
**free→paid first-sync backfill**, structural limits (branches/seats/devices)
**and à-la-carte add-ons** for paid tiers, **grandfathered + plan-versioned
pricing (§4.9)**, schema, permission wiring, edge cases, tests.

**Out of scope (later):** the PayMongo payment integration itself (its own
sub-project — QRPH via a Supabase Edge Function, secret key server-side only),
dunning content, BIR receipt format for the subscription charge, and the optional
quota-leasing hardening (§6.4 — documented, not built in v1).

---

## 2. Design principles (fair-to-customer, offline-first)

Hard constraints. Every decision below follows from them.

1. **A POS must never stop selling.** Core sale/refund/shift operations are never
   capped or billing-gated, even offline, even on Free, even when billing is
   unreachable.
2. **Never destroy user data to enforce a limit.** Hitting a limit blocks the
   *next* create; it never deletes or rejects what was already made. Downgrade
   never deletes — it freezes/reverts to read-only.
3. **The cloud is the value metric.** We meter **cloud sync + backup +
   multi-device + multi-branch + team**, plus advanced capability modules — never
   the number of receipts, and (v2) never local record counts. Local, single-
   device use is unlimited and free.
4. **Free is a real product, not a crippled trial.** A solo owner runs their
   whole shop on Free forever, on one device, fully offline.
5. **Soft limits with warning + grace, not surprise cut-offs.**
6. **The server is the only authority for cloud limits; clients are optimistic.**
   Structural cloud limits (branches/seats/devices) are enforced server-side; a
   tampered client can't self-grant.
7. **Transparent PHP pricing** with a published, verifiable annual discount.
8. **Sell at the moment of genuine need, never nag.** Upgrades are offered when
   the user actually reaches for something cloud unlocks (a 2nd device, a branch,
   protecting real data) — framed as *growth*, not a paywall. The free tier is a
   real product we **never shrink** and never hold data hostage in. (See §4.2–4.7.)

---

## 3. What we meter (the value metric)

The **primary gate is the cloud.** Everything that structurally *requires* the
cloud is what you pay for:

- **Cloud sync + automatic backup** — the headline value. Free is local-only.
- **Registered devices** — multi-device needs the cloud to sync between them.
- **Branches** — multi-branch is impossible without sync (branches share data).
- **Seats** — an *active* employee logging in **on their own device** needs sync;
  multiple staff on the *same* device is local and allowed on Free.
- **Advanced capability modules** — CRM depth, procurement, full reports/export,
  accounting/tax/budgets, multi-currency — gated by tier.

We deliberately do **not** meter:

- **Products / records / transactions / customers** — unlimited on every tier,
  including Free. (The v1 100-product cap existed only for *storage* cost; a
  local-only Free tier has no storage cost, so the cap is gone.)
- **Anything that runs purely on-device** — the on-device AI assistant, the
  audit *record*, and basic on-device fraud detection cost us ~₱0, so they stay
  **on for Free** as trust differentiators. What is paid is the *oversight
  surface* over that record: the Audit Logs viewer, the Fraud & Risk dashboard,
  and cross-device fraud sync (`audit: full`, Growth). The record itself is
  never withheld, and it always leaves via the free Data Export.

---

## 4. Plan tiers & PHP pricing

Currency: **Philippine Peso (₱)**. Tuned for PH micro-SMB reality — most of the
market nets ₱15k–40k/mo, so we judge cost in **₱/day** the way a store owner
does. Validate the absolute anchor against measured per-tenant COGS before launch
(§5); the ratios and limits stay.

Launch is **3 tiers — Free / Starter / Growth**. Business and Enterprise are
**not launched** (see below); they stay defined in the schema for when M6/M7.2
ship.

*Limits below are current as of the 2026-07-31 retune
(`20260731124330_plan_limits_retune.sql`, applied to prod 2026-07-31).
`plan_limits` v1 is the live source of truth — this table documents it, it does
not define it.*

| | **Free** | **Starter** | **Growth** (full access) |
|---|---|---|---|
| **Monthly** | ₱0 | **₱199** | **₱499** |
| **Annual** (2 mo free) | — | **₱1,990** | **₱4,990** |
| **≈ per day** | ₱0 | **~₱6.50** | **~₱16** |
| **Cloud sync + auto-backup** | ❌ **local only** | ✅ | ✅ |
| Devices | 1 | 3 | **♾️ unlimited** |
| Branches | 1 | 1 | 5 |
| Seats (own-device logins) | 2 (same device) | 3 | 15 |
| **Add-ons** (à la carte, §4.9) | — | *not sold yet* | *not sold yet* |
| Products / records | ♾️ local | ♾️ | ♾️ |
| **Modules** | | | |
| POS, Inventory, Expenses, Recipes | ✅ | ✅ | ✅ |
| On-device AI assistant | ✅ | ✅ | ✅ |
| Audit chain records everything | ✅ local | ✅ + backed up | ✅ + backed up |
| Audit log viewer (open it in-app) | — | ✅ | ✅ |
| Unusual Activity dashboard | — | — | ✅ |
| Data export (manual backup, incl. audit rows) | ✅ | ✅ | ✅ |
| CRM / customers | — | basic | ✅ full |
| Procurement / Suppliers | — | — | ✅ full |
| Reports: Sales, Inventory, Profit | ✅ | ✅ | ✅ |
| Reports: Branch Comparison + PDF/Excel export | — | — | ✅ |

**Growth is "every feature in the app, unlocked."** Devices are uncapped;
branches and seats stay metered, generously. Uncapping *those* too would flatten
ARPU at ₱499 forever — a 20-branch chain would pay what a single shop pays while
costing multiples of it in sync and storage — and §4.9 means an unlimited we
grant can never be walked back. Capacity headroom is the growth lever; features
are not.

**Audit is gated by depth, never by presence** (`audit: local | cloud | full`).
The hash-chained record runs on every tier — it costs ~₱0, it feeds on-device
fraud detection, and it is the BIR tamper-proofing claim.

The two surfaces above the record sit on **two different rungs** (split
2026-08-01):

- **`cloud` (Starter)** — the trail is backed up *and* browsable in-app: who did
  what and when. Previously `cloud` unlocked nothing at all, so Starter paid for
  a rung it could never reach; a backed-up log you cannot open is not a feature.
- **`full` (Growth)** — adds the **Unusual Activity** dashboard and cross-device
  fraud sync. That is what answers "is something wrong *across my branches*",
  a question only a Growth-shaped business has, and it is the genuinely
  Growth-priced half.

**Audit rows ride the always-free Data Export on every tier**, so gating either
surface never makes anyone's trail unreachable (§4.7 + BIR retrievability).

Costs nothing to give away: no migration was needed for the split —
`plan_limits.feature_flags` already carried `local`/`cloud`/`full` per tier, and
only the client's reading of them changed.

**Add-ons are defined and priced but not sold yet.** `plan_addons` and the
`branch_addons` / `seat_addons` / `device_addons` columns exist and are already
folded into `effective_limits_for()`; there is deliberately no purchase UI. Until
there is, a Growth tenant that outgrows 5 branches or 15 seats is granted
headroom by an admin `UPDATE subscriptions SET branch_addons = n`, which takes
effect immediately with no billing change.

*Future tiers (defined, not launched): **Business** ₱1,299 adds accounting /
tax / budgets (M6) + multi-currency (M7.2); **Enterprise** is sales-led (SSO /
SLA / priority support). Added on top of Growth when those features ship — never
a reprice of Growth (§4.9).*

**Free** = a solo micro-shop runs everything on one device, offline, forever —
unlimited products, full POS/inventory/recipes, on-device AI, local audit. The
only things it lacks are the cloud (backup/sync/multi-device/branch) and the
not-yet-built premium modules. **Starter (₱199 ≈ ₱6.50/day)** = "back up my data
and let me use my phone + tablet" — the cheapest, most honest upgrade, and the
key to converting the micro segment that would never pay more. **Growth (₱499 ≈
~₱16/day)** = **full access to everything shipped today** — cloud, multi-device,
multi-branch, a team, full CRM / procurement / reports, and the full tamper-proof
audit chain.

**Launch = Free + Starter + Growth**, all **100% backed by shipped features
today** — cloud sync, automatic backup, multi-device, the tamper-proof audit
chain, on-device fraud, CRM, procurement, and full reports all already exist.
There is deliberately **no Business or Enterprise tier at launch:** the old
₱1,299 Business tier was justified only by accounting/tax/budgets (M6) and
multi-currency (M7.2), *neither of which is shipped* — you can't charge for
features that don't exist yet. When M6/M7.2 land they become a **new tier added
on top of Growth**, never a price hike on existing Growth customers (§4.9).

**Structural growth is sold as add-ons, not tier jumps.** A Starter shop that
buys one more tablet adds a **+device** add-on rather than being forced all the
way up to Growth; likewise **+branch** and **+seats** on any paid tier (§4.9).
This scales revenue smoothly with the customer's real growth and makes the exact
tier anchor matter less — customers self-assemble the plan they need.

### 4.1 Data-loss is the risk — and the honest upgrade lever

Local-only Free means: if the device breaks, is uninstalled, or (on web) the
browser evicts local storage, **that data is gone — there is no cloud backup.**
This is handled, not ignored:

- **Manual export/backup stays on Free** (see the table) — a free user can always
  export their data to a file. Covers us and them.
- **Explicit first-run consent on Free:** *"Free plan stores data on this device
  only. It is not backed up. Upgrade to Starter for automatic cloud backup."*
- **Web-first-run is stronger:** browser storage (IndexedDB) can be evicted
  without warning, so on **web** we warn more firmly and steer toward Starter for
  anyone with real data. (Consider web-Free being an explicit "try-it" mode.)
- This is our **strongest, most honest upgrade driver** — "don't lose your
  business records" sells Starter better than any feature gate.

### 4.2 The Free experience — complete, honest, forever

Free must feel like a *finished product for a solo shop*, not a locked demo. The
goal: an owner installs it and is **selling within minutes**, with nothing
nagging them.

- **Everything on-device works, in full:** POS, inventory, products, recipes,
  expenses, basic reports, the on-device AI assistant, and local audit + basic
  fraud. No feature is teased-then-blocked.
- **No expiry, no trial countdown.** Free is forever. This builds the trust that
  makes someone comfortable enough to later pay.
- **One honest truth, surfaced calmly (not in red alarm):** a small, always-
  visible **"Backup: off — saved on this device only"** status, with a one-tap
  *"Protect my data"*. Paired with a **manual Export** that is always one tap away
  (never hidden) so even a non-paying user can keep their own copy.
- **We never shrink Free later.** What's free today stays free. Quietly clawing
  back the free tier is the fastest way to lose an SMB's trust — forbidden.

### 4.3 The upgrade journey — offered at the moment of real need

Never a launch-time popup or a random interstitial. An upgrade is surfaced only
when the user **reaches for something the cloud actually unlocks**, in context,
one tap, dismissible:

| The moment they… | What we gently offer |
|---|---|
| open the app on a **second device** | "Sell on your phone *and* your tablet — turn on cloud for ₱6.50/day." |
| try to add a **branch** | "Running a second location? Growth connects your branches." |
| add an **employee who needs their own device** | "Give your staff their own login — upgrade to sync." |
| have **accumulated real data** (e.g. 30+ days of sales) | "You've recorded ₱X in sales — all on this one phone. Back it up so you never lose it." |
| tap a **paid module** (procurement / CRM depth / accounting) | shows exactly what the tier unlocks + ₱/day. |

Every prompt is framed as **"you're growing"**, shows the concrete unlock and the
₱/day price, and **never blocks the current sale.** Paying should feel like a
milestone, not a fine.

### 4.4 "Cloud's on us" — let them taste paid, safely

New accounts get **cloud backup ON automatically for the first 14 days** (a light
Starter trial). This does two jobs at once: it **protects new users during the
riskiest early period** (before they'd think to back up), and it lets them *feel*
the value of backup + multi-device.

At day 14, if they haven't upgraded:
- **Graceful revert to Free (local):** their data stays fully usable on the
  device; the cloud copy is **frozen, not deleted**, for a win-back window.
- A clear, non-punishing heads-up + **one-tap Export** + **one-tap Upgrade** —
  never a lockout, never a scare.

(Optionally offer a longer Growth trial to showcase CRM/full reports — same
graceful-revert rules.)

### 4.5 The paid experience — instant, visible, reassuring

Paying must immediately *feel* worth it:

- **On upgrade:** an instant **"Your data is now backed up ✓"**, and the
  first-sync backfill (§7.2) is shown as a positive *"protecting your data…"*
  progress moment, not a scary technical sync.
- **Multi-device that just works:** sell on one device, see it on another.
- **Usage meters are informative, not anxious:** "2 of 3 seats used" — never a
  red "LIMIT!" wall.
- **Value receipts (churn reducer):** an occasional, quiet summary — *"This month
  your plan backed up your data 30× and synced 2 devices."* Reminding people what
  they're paying for is the cheapest way to keep them paying.

### 4.5a The Plans surface — two shapes, one per situation

`BillingPlansTab` renders one of two things, and never both:

**Not subscribed** (`free`, `lapsed`, `trialing`) — the plan ladder. Free is
shown and marked as the current plan, so the tab always answers "where am I".
The billing-period toggle sits above the cards.

**Subscribed** (`active` or `past_due` on a paid `plan_code`) — a single
`CurrentPlanCard` and no ladder at all. Once someone has bought, a grid of
buyable cards is noise; the two questions they actually arrive with are *when am
I charged again* and *how do I cancel*, so the card leads with the tier, the
price, the renewal date, and a **Manage subscription** button that deep links to
Google Play's subscriptions screen (`IapService.manageSubscriptionUri`).
Cancelling and changing payment method belong to Google — Play policy requires
it and no card details ever touch this app. Beneath that: the benefit list and
the usage meters, so "am I near a cap" is answered without a tab switch.

A quiet **Change plan** link reveals the ladder on demand. In that mode the Free
card is filtered out (you reach Free by cancelling in Play, not by tapping a
card here) and a line states the proration rule the client actually implements:
upgrades apply immediately with Google crediting unused time, downgrades defer
to the end of the period (`BillingCubit._replacementModeFor`).

The card renders from the entitlement cache, so a subscriber sees their plan,
status, renewal date and meters **offline**; only the price and benefit list
need the catalog, and they are simply omitted when it hasn't loaded.

**Plan cards state what a tier means, not just what it counts.** Every
capability row carries a plain-language gloss ("3 devices" → *"Phones, tablets
or computers signed in at the same time"*), paid tiers show the daily
equivalent, and the entry tier names the two headline things it does **not**
give you. A plan page that only ever lists what you have makes Free look
complete — and people then lose data they assumed was backed up. The row set is
derived from the server's `plan_limits` in one place (`plan_benefits.dart`),
shared by the ladder and the summary so the two can never drift.

**The grandfathered-price chip is gated, not raw.** `grandfathered_price` lives
on the `subscriptions` row and outlives the subscription itself, so rendering it
straight from the entitlement put a lapsed Growth tenant's "₱499" on the Free
card they had fallen back to. A lock is only shown when all four hold: the
tenant is in a paying status, the card is their own tier, the tier is paid, and
the locked figure is genuinely *below* today's list price — a lock equal to list
is just the price, and saying "locked" there is noise.

### 4.6 Downgrade & lapse — graceful, never punishing

(Experience layer; the mechanics are §7.3–7.4.)

- **Payment fails →** friendly grace period with gentle reminders; **the POS keeps
  selling the whole time.**
- **Downgrade →** *"Your data is safe on this device — cloud is paused."* Nothing
  deleted, no lockout, one-tap reactivate, and instant restore if they come back
  within the win-back window.
- The tone throughout: *we're holding your spot*, not *we cut you off*.

### 4.7 Anti-patterns we will not ship

Explicit guardrails so no future build slips into dark patterns:

- ❌ Popups that block or interrupt a sale.
- ❌ Fake urgency / countdown timers / "only today" pricing.
- ❌ Hiding or disabling the Export button to trap data.
- ❌ Deleting or holding user data hostage on lapse/downgrade.
- ❌ Silently shrinking the Free tier after people rely on it.
- ❌ Nagging on every launch instead of at a real moment of need.

### 4.8 Free vs Paid — the experience at a glance

| Experience | **Free** (local) | **Paid** (cloud, from ₱199/mo) |
|---|---|---|
| **Selling / POS** | Full, offline, never blocked | Full, offline, never blocked |
| **Products / records** | ♾️ unlimited | ♾️ unlimited |
| **Where your data lives** | This device only | Backed up to the cloud automatically |
| **If the device is lost/broken** | Data gone unless you exported | Restore from cloud |
| **Data safety** | Manual Export ("Backup: off") | Auto backup + restore |
| **Devices** | 1 | 3 (Starter) → unlimited (Growth) |
| **Branches** | 1 | 1 (Starter) → 5 (Growth) |
| **Staff on their own devices** | No (shared device only) | Yes |
| **Audit log + fraud** | Recorded on-device | Recorded + backed up; the viewer & fraud dashboard are Growth |
| **On-device AI assistant** | ✅ | ✅ |
| **First 14 days** | Cloud backup ON, "on us" | (already included) |
| **Upgrade prompts** | Only at a real need-moment, dismissible, never blocks a sale | — |
| **Export your data** | Always, one tap | Always, one tap |
| **If you stop paying** | (already free — nothing changes) | Reverts to Free-local: data kept, cloud frozen not deleted, POS keeps selling |
| **Expiry** | Never — free forever | — |
| **Price** | **₱0** | **from ₱199/mo (~₱6.50/day)** |

The whole story in one line: **Free gives you a complete shop on one device;
paying adds the cloud — backup, more devices, branches, and a team — the moment
your business actually needs it.**

### 4.9 Trust-safe scaling — grow by *adding*, never by taking away

The pricing model is built so we can iterate on price and packaging for years
**without ever making an existing customer worse off.** The rule: **scale revenue
by *adding* — more free→paid converts, expansion as a shop grows, and new
capability tiers — never by raising what current customers already pay or
shrinking what they have.** Five mechanisms enforce it:

1. **Grandfathered pricing, forever.** Whatever price a customer signs up at, they
   keep for life while subscribed. A new list price applies to **new** signups
   only. This lets us raise the *published* price anytime at zero trust cost, and
   we frame it as a reward — *"early adopters keep this price forever."* It doubles
   as churn armor: leaving means losing the locked rate.
2. **Plan versioning (entitlement snapshotted onto the subscription).** Price and
   feature-set are **not** resolved live against a mutable `plans` row. The
   `subscription` is pinned to a `plan_version` and carries a **snapshot** of the
   price + limits + `feature_flags` it was sold with. Repricing or repackaging is a
   **new version for new customers**; existing subs are untouched, and "move to the
   newest plan" is **opt-in only.** (Limits we only ever *raise* may still resolve
   live; price and feature-set are pinned.)
3. **Add-ons for smooth expansion.** Device / branch / seat **add-ons** on top of
   any paid tier let spend grow gradually with the business — no jarring 2.5× tier
   cliffs, no cannibalized middle tier, and the base anchor stops being a
   high-stakes guess. Generalizes the existing `seat_addons` idea.
4. **Monetize *new* value only.** New revenue comes from **new capability** sold as
   new tiers/add-ons (M6 accounting, M7.2 multi-currency, deeper reports) — never
   from removing or degrading something people already rely on. This is §4.2/§4.7's
   "never shrink Free / never claw back" extended to *paid* tiers too.
5. **Published, dated pricing + a change protocol.** The pricing page states
   *"Prices effective as of [date]; existing customers keep their signup price,"*
   so future changes are non-events. Every pricing change obeys one commitment:

   > Existing customers never worse off (grandfathered price + kept limits &
   > features) · announced ahead in-app + email with the reason · new price/tier
   > applies to new signups only (or to existing users only on a *voluntary*
   > upgrade) · Free never shrinks · any degrade freezes/reverts to read-only,
   > never deletes.

Every plan change is written to `subscription_events` (hash-chained, §6.3), so the
audit trail *proves* no one's plan was silently altered — the trust claim is
verifiable, not just a promise.

---

## 5. Pricing is derived, not guessed

1. **Free is COGS-free.** Local-only ⇒ no Supabase rows/storage/egress/sync ⇒
   **~₱0 marginal cost per free user.** So Free is sustainable at any scale — we
   never subsidize free users. This is the foundation that lets the paid entry be
   cheap.
2. **Starter clears cloud COGS with margin.** A small synced tenant costs a low
   single-digit USD/mo on Supabase amortized (rows + storage + egress + realtime);
   ₱199 (~$3.40) covers it with healthy margin. **Validate against measured
   numbers before launch** — only this anchor moves; ratios stay.
3. **Value ladder + add-ons.** ₱0 → ₱199 → ₱499 is a clean three-rung launch; the
   ₱199 rung bridges the too-big ₱0→₱499 gap that loses micro businesses, and
   **device/branch/seat add-ons fill the space between rungs** so a growing shop
   pays a little more gradually instead of hitting a 2.5× cliff (§4.9). A **future
   higher tier** (Business, when M6/M7.2 ship) extends the ladder upward without
   repricing anyone.
4. **Per-day framing is the honest sell.** ₱6.50/day (Starter) is "one text-load"
   money — almost any real store pays that for backup + a second device.

### 5.1 Yearly discount — calculated, not invented

Industry-standard, legible **"2 months free on annual"**: pay for 10 months, get
12.

```
annual_price        = monthly_price × 10
effective_monthly   = annual_price / 12
discount_percentage = 1 − (annual_price / (monthly_price × 12))
                    = 1 − (10/12) = 16.667%
```

| Plan | Monthly | ×12 (no discount) | Annual (×10) | Effective /mo | Saves |
|---|---|---|---|---|---|
| Starter | ₱199 | ₱2,388 | **₱1,990** | ₱165.83 | ₱398/yr (16.67%) |
| Growth | ₱499 | ₱5,988 | **₱4,990** | ₱415.83 | ₱998/yr (16.67%) |

*(Business ₱1,299 → ₱12,990/yr is pre-computed for a future tier via the same
constant — not a launch price.)*

A single `discount_months_free = 2` constant drives every annual price, so prices
can't drift and customers can verify the saving themselves. (Annual is
cash-flow-friendly at the low end: ₱1,990/yr is far more digestible for a micro
shop than ₱4,990.)

**Proration (fair rules):** upgrade mid-cycle = prorated difference; downgrade =
at period end, premium data read-only, never deleted; annual unused months
refundable within the period (configurable).

---

## 6. Enforcement — hugely simplified by the local-vs-cloud model

The v1 nightmare was: *"Free, 100-product cap, 10 offline devices each create
100 → 1,000 products on reconnect — what happens?"* **In v2 that scenario is
impossible**, because:

- **Free = 1 device, no sync** → there is no multi-device reconciliation on Free
  at all, and
- **Products are uncapped on every tier** → there is no high-volume count to
  overshoot.

So enforcement splits cleanly:

### 6.1 Free tier — nothing to enforce server-side

Free never syncs business data. There is no cloud count, no reconciliation, no
soft-lock. The only "limit" is **1 device**, enforced trivially: a second device
simply can't turn on cloud sync (there is none) and can't register (registration
is a paid, online operation — §6.3). Local records are unlimited.

### 6.2 Paid tiers — only low-volume *structural* limits, checked at the cloud

Paid tiers meter only **branches, seats, devices** — all low-volume and all
created through cloud-aware operations:

- **Device registration is online-only** and checked server-side against
  `max_devices` at register time. This is also what bounds everything else.
- **Branch / seat creation** uses an edge soft-check (cached limit + local count)
  for instant UX, and is enforced for real by **RLS `count < limit` on INSERT**.
  Because these are low-volume and paid devices are online-reachable, the rare
  offline-overshoot case is handled by the same **accept-all + soft-lock new
  creates + never delete** rule as v1 — but it now applies to a handful of
  branches/seats, not thousands of products.

No product reconciliation machinery is needed anywhere. The heavy `over_limit` /
`creation_locked` product logic from v1 is **dropped** (kept only, optionally, for
branches/seats if we ever want a hard structural cap).

### 6.3 Why this is secure (a tampered client can't win)

- **Cloud limits are enforced server-side under RLS**, against `plan_limits ⨝
  subscriptions`. A client can lie about local state but can't shrink the server's
  authoritative view.
- **Entitlement is server-signed and client-read-only.** A device can't grant
  itself the cloud or a higher tier.
- **Device registration is online-only**, so the cap can't be bypassed offline —
  and without a registered device, there is no sync to abuse.
- **Subscription/limit changes are logged** to `subscription_events` (hash-chained,
  reusing the shipped M1 chain) — auditable.

### 6.4 Optional hardening — quota leasing (documented, not in v1)

If a paid tier ever needs a *true* hard cap on a structural resource, the server
can lease N slots to a device while online. **Default off** — soft-cap + RLS is
better UX. Schema stays lease-compatible so it can be switched on later without
migration churn.

---

## 7. Entitlement = the gate (extends the existing two layers)

A business's effective access is a **third, outermost layer** over the current
module + permission gates:

```
effective_access(feature) =
      plan_entitlement(feature)        // tier includes it (feature flag)
  AND cloud_or_local_ok(feature)       // cloud features require a cloud tier
  AND business_module_enabled(feature) // owner toggled it on
  AND permission_service.can(...)      // employee has permission
```

`PermissionService.canAccessFeature()` consults a new plan-aware
`EntitlementService` first (cheapest check). **No existing permission logic
changes** — we wrap it.

### 7.1 The sync layer is gated on entitlement (v2 core mechanism)

- **`SyncService` runs only when the tenant is on a cloud tier.** On Free it is
  **disabled** — Drift is the sole store, no push/pull, no Supabase business-data
  writes. (Free users still have a Supabase *auth* account for identity + the
  upgrade path; they just don't sync business data.)
- Cloud features (multi-device, branches, tamper-proof audit, fraud sync, CRM
  cloud, reports export) are entitlement-gated in Bloc/UseCase **and** router
  guards, not just hidden in the UI.

### 7.2 Free → paid: the first-sync backfill (new flow to build)

On upgrade, all existing **local** data must be pushed to Supabase in one initial
sync:

- Enqueue every local business row as `pending` upload; run a bounded, resumable
  initial push (respect existing `sync_status` lifecycle + LWW).
- One-time COGS spike; show progress UI; never block selling during backfill.
- After backfill, normal background sync takes over.

### 7.3 Paid → Free (or lapse): never destroy, revert to local

- Existing data **stays fully usable on the primary device** (it's already in
  Drift). Cloud sync stops; other devices lose sync access.
- Cloud copy is **frozen/retained** through the grace window (not deleted); on
  re-upgrade within grace, sync resumes.
- Premium *modules* degrade to read-only per the grace rules below. Core POS/
  inventory/expenses keep working.

### 7.4 Offline entitlement grace (for cloud *feature* access)

Entitlement snapshots are cached locally (read-only) with `valid_until` /
`grace_until`. If billing is unreachable, premium **features** stay active until
`grace_until` (default **14 days**, longer for annual). After grace **and** a
server-confirmed lapse, premium features degrade to read-only and the account
reverts toward Free — but **core POS/inventory/expenses keep working**. Grace is
measured against **last server-sync time**, not device clock (clock-tamper
resistant).

---

## 8. Schema

### Supabase (source of truth)

- `plans` — `code` (`free|starter|growth|business|enterprise`), `version`
  (int — bump to reprice/repackage; old versions stay readable so grandfathered
  subs keep resolving, §4.9), name, `price_monthly` (₱), `is_active`. **Launch
  activates `free|starter|growth` only**; `business|enterprise` stay defined with
  `is_active = false` until M6/M7.2 ship.
- `plan_limits` — keyed by (`plan_code`, `plan_version`); `cloud_enabled`
  (bool — the v2 primary gate), `max_branches`, `max_seats`, `max_devices`, JSONB
  `feature_flags` (`{"crm":"basic","procurement":false,"accounting":false,...}`).
  No `max_products` (unlimited everywhere).
- `plan_addons` — catalog of à-la-carte add-ons (`code` = `device|branch|seat`,
  `price_monthly` ₱, `unit_qty`) a paid tier can buy on top of its base limits
  (§4.9).
- `subscriptions` — `business_id` (PK/tenant), `plan_code`, **`plan_version`**
  (pins the version this sub was sold), `billing_period` (`monthly|annual`),
  **`entitlement_snapshot`** (JSONB — price + limits + `feature_flags` locked at
  purchase, so repricing new customers never touches this one, §4.9),
  **`device_addons` / `branch_addons` / `seat_addons`** (purchased extras added to
  the base limits), `status` (`trialing|active|past_due|canceled`),
  `current_period_start/end`, `trial_end`, `grace_until`. One per business.
  **Written service-role only** (a PayMongo webhook *or* a manual admin grant —
  both are service-role writes; the entitlement engine doesn't care which).
- `devices` — `id`, `business_id`, `label`, `registered_at`, `last_seen_at`,
  `revoked_at`. Registration is **online-only**; enforces `max_devices`. Build
  alongside M-BIR's `pos_devices` model.
- `subscription_events` — append-only, **hash-chained (reuses M1)**: plan
  changes, upgrades/downgrades, lapses.
- (lease-ready, off by default) `quota_leases`.

RLS: a business reads only its own rows; **subscription/limit writes are
service-role only**. Structural-limit RLS on `branches`/`employees` reads the
tenant's **effective limit = pinned `plan_limits` (by `plan_version`) + the
subscription's add-ons** — never a live-mutable plan row, so grandfathered subs
enforce the limits they were actually sold (§4.9).

### Drift (local, read-only cache — written only by the sync path)

- `entitlement_cache` — `business_id`, `plan_code`, `plan_version`,
  `billing_period` (`monthly`/`annual`, schema v59 — the summary card must be
  able to say "/month" vs "/year" offline; `get_my_entitlement()` already
  returned it, we simply weren't keeping it), `cloud_enabled`, `feature_flags`
  JSON (from the sub's snapshot), effective
  `max_branches`, `max_seats`, `max_devices` (base + add-ons already folded in),
  `device_addons`/`branch_addons`/`seat_addons`, `valid_until`, `grace_until`,
  `last_server_sync_at`.
- `resource_usage_cache` — `business_id`, `branch_count`, `active_seat_count`,
  `device_count`, `synced_at` (drives "2 / 3 seats" UI). No product count.

Schema-version bump + additive migration both sides (per `CLAUDE.md`; rollback =
drop the cache tables locally, drop billing tables + policies on the server).

---

## 9. Permissions & wiring (mandatory checklist)

- `PermissionKeys`: `billing.view`, `billing.manage`, `nav.billing`.
- `AppPermission`: `viewBilling`, `manageBilling`.
- `AppFeature`: `billingSubscription` → **not** module-gated (an owner must reach
  billing even on a lapsed/Free account), `navKey = 'nav.billing'`.
- Role + default matrices: `manageBilling` = **Owner / Business Owner only**;
  `viewBilling` may extend to Branch Manager (read-only). Run
  `dart run tool/diff_matrices.dart`.
- New `EntitlementService` (`lib/core/permissions/entitlement_service.dart`);
  `PermissionService` consults it first; registered in `di.dart`. Resolves from
  the subscription's **pinned `plan_version` snapshot + add-ons** (§4.9), not a
  live-mutable plan row.
- **`SyncService` gains an entitlement check** — no-ops on Free (§7.1).
- New `billing` feature folder: plan picker with the ₱/day framing, **add-on
  purchase (device/branch/seat)**, upgrade/downgrade, invoice history,
  seat/branch/device usage meters, a reusable account-status banner, the
  **cloud-backup / data-loss consent** widgets, and a **grandfathered-price**
  indicator (shows the locked signup price when the list price has since moved).
- **Experience widgets (§4.2–4.7):** a calm always-visible **backup-status
  indicator** (Free = "on this device only" + one-tap Protect), **contextual
  upgrade prompts** fired at real need-moments (2nd device / branch / own-device
  seat / data-accumulated / paid module) — reusable, dismissible, never
  sale-blocking; the **first-14-day "cloud's on us" trial** + graceful revert; and
  periodic **value-receipt** summaries. Prompts live in `lib/core/widgets/` so
  they stay consistent and are easy to audit against the §4.7 anti-patterns.

---

## 10. Edge cases (explicitly handled)

- **Free device loss / web eviction** — data-loss is real on Free; mitigated by
  manual export + explicit consent + steering web users to Starter (§4.1).
- **"Cloud's on us" 14-day trial expiry** — reverts to Free-local with data fully
  preserved on-device; cloud copy frozen (not deleted) for the win-back window;
  heads-up + one-tap export/upgrade, never a lockout (§4.4).
- **Free → paid first-sync backfill** — push all local data on upgrade; resumable;
  never blocks selling (§7.2).
- **Paid → Free / lapse** — local data stays usable on the primary device; cloud
  frozen not deleted; premium modules read-only; core POS unaffected (§7.3).
- **Downgrade below current usage** (say 5 branches → Free's 1) — **revised
  2026-08-01.** The original rule ("existing kept & operational; block new
  creates only") left the plan buyable once and kept forever: ₱499 for one month
  of Growth bought five permanent branches. The rule now is an **active set**:
  exactly N stay active (N = the plan cap), the excess is locked read-only, and
  nothing is ever deleted. See `UPSENSO_LIMITS_ENFORCEMENT.md` for the full
  contract. Safety property: the branch currently open in POS is always inside
  the default active set, so a downgrade can never stop a till mid-shift.
- **Suspend vs delete employee:** suspending frees a seat immediately;
  reactivating re-checks the seat limit (client pre-check *and* the
  `enforce_seat_cap_on_reactivate` trigger). Over-cap staff after a downgrade
  are suspended, never deleted, and the owner always keeps their own seat.
- **Deleting a branch frees its slot immediately** — `countForBusiness` excludes
  pending-delete rows. Counting them pinned an offline tenant at their cap
  forever: delete a branch, still can't create its replacement.
- **Device registration while offline:** not allowed — needs the server. This is
  what bounds a paid account to its device cap. A device that comes back
  `cap_reached` keeps selling locally and surfaces a device-cap notification;
  only its cloud backup is affected.
- **Trial expiry / payment failure:** `past_due` keeps full access through
  `grace_until` with escalating notifications; only then degrade.
- **Paid but unreachable** (offline over a renewal date) — `unverified` keeps the
  tier and cloud alive for 14 days (30 annual) from the last server contact,
  then degrades. Distinct from `past_due`: that means *we know it failed*, this
  means *we don't know*. Without it, a merchant Play had already charged was
  silently downgraded for having no signal.
- **Clock tampering:** grace, the verification window and lease expiry are all
  keyed off last server-sync time, never the device clock alone.

---

## 11. Tests (critical paths)

- Entitlement resolution: tier ∩ cloud-flag ∩ module ∩ permission for each
  feature/tier.
- **Free is local-only:** `SyncService` no-ops on Free; no Supabase business-data
  writes; unlimited local records work; export works.
- **Free → paid backfill:** all local rows push on upgrade, resumable, no loss,
  selling never blocked.
- **Paid → Free / lapse:** local data stays usable; cloud frozen not deleted;
  premium modules read-only; core POS never blocked; re-upgrade within grace
  restores sync.
- **Structural limits (paid):** branch/seat INSERT blocked at cap server-side
  (RLS) even if the client bypasses the UI; device registration blocked at cap
  and offline. **Effective cap = base limit + add-ons** — an add-on raises the cap
  and the usage meter reflects it.
- **Grandfathering / plan versioning (§4.9):** repricing or repackaging a plan
  version leaves an existing subscription's entitlement (price + limits +
  features) unchanged; new signups get the new version; migration to a newer
  version happens only on explicit opt-in.
- Pricing math: `annual = monthly × 10`, `discount = 16.667%`, proration on
  upgrade, no clawback on downgrade.
- Offline grace: full access within grace; degrade after grace + confirmed lapse;
  core POS never blocked; clock-tamper doesn't extend grace.
- `subscription_events` hash chain verifies (reuses the M1 verifier).
- Manual admin grant and a (future) PayMongo webhook both write `subscriptions`
  identically (service-role) and produce the same entitlement.
- **Experience guarantees (§4):** the "cloud's on us" 14-day trial reverts to
  Free-local with data preserved + cloud frozen-not-deleted; contextual upgrade
  prompts **never block an in-progress sale**; the Export action is reachable on
  every tier including Free; a lapse/downgrade never deletes data or stops the POS.
```
