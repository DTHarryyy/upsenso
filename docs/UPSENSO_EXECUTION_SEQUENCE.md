# UPSENSO — Execution Sequence (what to do next, in order)

> Status: **active build sequence** · Branch: `claude/platform-features-roadmap-7bqdgn`
> This is the **ordered task list** from the current codebase to the product
> vision. The *what & why* live in `UPSENSO_PRODUCT_ROADMAP.md`; the *how* for the
> hard parts live in `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` and
> `UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md`. **This doc says what to do first.**

## Priority override (current decision)

The product owner chose to **lead with visible value** rather than the trust
spine. So the near-term order is **M2 (proactive AI insights) → M5 (CRM
foundation)**, with **M1 (fraud + audit chain) deferred to the milestone right
after** (its full spec stays valid, just rescheduled). The phase numbering below
is unchanged for reference; the *active* work order is:

1. **Step 0 — Foundations** (below)
2. **Phase 3 — M2 Proactive AI Insights**  ⬅️ *in progress*
3. **M5 — CRM foundation** (customers + purchase history; loyalty stretch)
4. **Phase 1 + 2 — M1 audit chain + fraud engine** (deferred, next milestone)

Rationale: the AI assistant already exists, so making it *proactive* is the
highest-leverage, most demoable win; CRM fills the biggest functional gap
(customers are only a text field today). See the chat decision for full reasoning.

## How to use this

- Work **top to bottom** *within the active order above*. Each step is gated on
  the one before it.
- Finish a step *completely* (code → codegen → migration → RLS → tests → device
  QA) before starting the next. Vertical slices, not many half-built features.
- `[ ]` = todo · `[~]` = in progress · `[x]` = done. Update as you go so any
  session (yours or a fresh Claude one — no memory between sessions) resumes here.
- **Every step ends with a CHECKPOINT** — don't proceed until it's green.

---

## Step 0 — Foundations (do once, ~0.5 day)

- [ ] `flutter pub get`; confirm `flavors/dev.json` exists with Supabase keys.
- [ ] Baseline green: `flutter analyze` and `flutter test` both pass on this
      branch *before* changing anything.
- [ ] Add `crypto` to `pubspec.yaml` (needed for the audit hash; first-party,
      web-safe) and re-run `flutter pub get`.
- [ ] Confirm Supabase project access and that `supabase/migrations/` is the
      source of truth (95 migrations today).

**CHECKPOINT:** clean `flutter analyze` + `flutter test`, app runs.

---

## Phase 1 — M1.1 Tamper-Evident Audit Chain  *(~1 week)*

Spec: `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` Part 1 + the **hardened plan**
(2026-07-03, adversarial-review revision — threat model T1–T14). Built
2026-07-03; deltas from the original spec are noted inline.

1. [x] **Canonical serializer** — `lib/core/audit/audit_hash.dart`. Platform-
       safe custom JSON encoder (VM/web double-rendering split), second-
       precision timestamps (Drift stores unix SECONDS), entity_id normalized
       like the sync mapper (uuid-only server column).
   - [x] Tests (12): stability, key-order independence, UTC format, int/double
         equivalence, corrupted-metadata determinism.
2. [x] **Drift schema** — v52→**53** (52 was taken by CRM): `seq`, `prevHash`,
       `entryHash` + **`deviceUid`** (the old `device_id` is a non-persistent
       display label — a real installation uid had to be minted:
       `lib/core/device/device_identity_service.dart`, secure-storage-backed).
3. [x] **Codegen** run.
4. [x] **Supabase migration WRITTEN** —
       `supabase/migrations/20260703000002_audit_chain_columns.sql`: adds
       `seq`/`device_uid`/`synced_at` (adopts the pre-existing unused
       `previous_hash`/`hash` columns), partial unique index `ux_audit_chain`
       (synced history becomes immutable), `get_audit_chain_heads()` +
       `get_my_device_chain_head()` RPCs, seeds `audit_logs.verify`
       (owner-only, matching audit_logs.view). **NOT YET APPLIED.**
5. [x] **Write path** — chain allocation in one Drift transaction + a write
       queue; **genesis-resume** (reinstall with surviving uid continues from
       the server head instead of colliding forever; offline ⇒ fresh uid).
   - [x] Tests (9): seq/genesis/linking, concurrency, resume-online,
         rotate-offline, tenant guard.
6. [x] **Verifier** — `audit_chain_verifier.dart`: per-device walk, pruned-head
       tolerance, seq-gap/link/hash breaks, online truncation check via the
       heads RPC (own device only — other devices' lag is not tamper).
   - [x] Tests (8).
7. [x] **UI hook** — "Verify integrity" on the Audit Logs page +
       per-device report dialog (`audit_chain_verify_dialog.dart`), gated by
       `audit_logs.verify` (owner-only by default, override-grantable).
8. [x] **Coverage fixes (T9 — the chain only proves what's logged):**
       `saleCreated` moved into `CheckoutService` (the AI and legacy checkout
       paths were never logging sales); manual stock movements now log from
       `StockMovementService`; module toggles log locally immediately (not
       only after a remote push); refund-approval settings changes now audited
       (new `refundSettingsChanged`) with old→new values; `productUpdated`
       now records per-variant `price_changes`.
9. [x] **Sync hardening** — mapper carries the chain fields; the audit push no
       longer swallows a 23505 from `ux_audit_chain` (marked failed with a
       `CHAIN_CONFLICT` marker → consumed by the AUDIT_TAMPER rule).

**CHECKPOINT (code): ✅** chain writes + tamper/truncation detection verified by
tests; analyze clean; full suite green. **Pending: migration apply + on-device QA.**

---

## Phase 2 — M1.2 Fraud Detection Engine  *(~1.5 weeks)*

Spec: Part 2 + hardened plan. Built 2026-07-03. Replaces the mock `alert`.

8.  [x] **Permissions wiring:** `fraud.view` / `fraud.resolve` / `nav.fraud` (+
        `audit_logs.verify`) → `AppPermission` → `AppFeature.fraudAlerts`
        (module `audit` — engine itself IGNORES the module gate, T7) → both
        matrices (Owner all; BM view+resolve+nav, **verify is owner-only** like
        audit_logs.view; Cashier/Inventory none) → `_moduleCodeForKey` +
        nav-key mapping → "Fraud & Risk" group in the employee-permissions
        editor. Matrix sync locked by `test/core/permissions/fraud_permissions_test.dart`.
9.  [x] **Drift v53→54** — `fraud_flags` table + DAO (insert-if-new dedupe,
        triage-only `resolve`, `markSuperseded` for cross-device races) +
        unique `(business_id, dedupe_key)` + **local rule-query indexes** on
        refunds/stock_ledger.
10. [x] **Supabase migration WRITTEN** —
        `supabase/migrations/20260703000003_fraud_flags.sql`: seeds the fraud.*
        permission codes (roles + templates + recompute — the CRM-gap lesson),
        table + RLS (SELECT tenant ∧ fraud.view ∧ **branch-scoped**; INSERT
        tenant; UPDATE fraud.resolve ∧ branch ∧ **self-resolution block**; no
        DELETE) + **freeze trigger** (only status/resolution fields may ever
        change — T10). **NOT YET APPLIED.**
11. [x] **Rule framework** — `FraudRule` + `FraudScanContext` +
        **hardcoded `FraudDefaults`** (locked decision: no editable
        `fraud_settings` in v1 — no threshold-tampering surface) + pure
        `RobustBaseline` (median/MAD, spread-floored, cold-start fallback).
12. [x] **TEN rules** (spec's `SALE_AFTER_SHIFT`/voids dropped — no shift/void
        data exists; replaced per the adversarial review):
        `AUDIT_TAMPER` (critical; verifier + CHAIN_CONFLICT scan),
        `TIME_REVERSAL` (clock rollback vs chain order), `EXCESSIVE_REFUNDS`
        (floors + baseline), `REFUND_STRUCTURING` (clustering just under the
        approval threshold), `QUICK_REFUND` (same-cashier sale→refund in
        minutes; no-restock boosts), `HIGH_DISCOUNT`, `SHRINKAGE_SPIKE`
        (cost-weighted), `CONTROL_CHANGE` (audit module off / threshold raised
        / role change / sensitive+self overrides), `ORPHANED_RECORD` (records
        written AROUND the audit trail — owner-mirror-gated),
        `PERMISSION_PROBING` (denial recon).
    - [x] Tests: 21 rule tests (positive/negative/boundary/dedupe) + 6
          baseline-math tests.
13. [x] **Engine** — `fraud_detection_engine.dart`: **no persisted watermark**
        (T12 — sweeps always rescan the trailing 30d), dedupe insert-if-new,
        owner-as-subject downgrade, per-rule flag cap + summary aggregation,
        every new flag writes a **chained** `fraudFlagRaised` audit entry (T8).
        Registered in DI. 7 engine tests.
14. [x] **Triggers** — post-commit incremental hooks in `CheckoutService`
        (HIGH_DISCOUNT), `RefundService` (refund rules), `StockMovementService`
        (SHRINKAGE_SPIKE); periodic full sweep rides `SyncService.onSyncCompleted`.
15. [x] **UI swap** — `mockFraudAlerts` deleted; `FraudCubit` →
        `FraudFlagsDao.watch` (branch-scoped client mirror; employee/branch
        name resolution); resolve/dismiss with note, gated by `fraud.resolve`
        + client self-resolution mirror, writes `fraudFlagResolved`; routed
        for the first time (`/more/fraud`, Branch 13, permission+module
        guards, sidebar + More-drawer entries). `fraud_flags` push/pull wired
        into `SyncService` (dedupe-conflict ⇒ supersede, not tamper-signal).

**CHECKPOINT (code): ✅** refund/discount/shrinkage/structuring abuse raises
flags in tests; chain break ⇒ CRITICAL; matrices in sync; **flutter analyze
clean (1 pre-existing warning), full suite 177 tests green.**
**Pending: both migrations applied + on-device QA (incl. live RLS
self-resolution check).**

> **M1 is now shippable** once the two migrations are applied and device QA
> passes.

---

## Phase 3 — M2 Proactive AI Insights  *(~2 weeks)*

Spec: `UPSENSO_PRODUCT_ROADMAP.md` M2. Reuses the existing AI pipeline.

16. [~] **Analytics tool methods** in `ai_tool_service.dart` (branch-filtered,
        permission-aware like existing queries):
    - [x] `getSalesTrend` (+ `previousPeriod` helper, `SalesTrendResult`) and
          `getApprovedExpenseTotal` — with pure-logic unit tests for the
          period math. **Verified green locally 2026-06-30.**
    - [x] `getTopProducts` (thin ranking wrapper over `getSalesByProduct`) and
          `getLowStockCount` (reuses `ProductVariantsDao.getLowStockByBusinessId`
          so it matches the dashboard low-stock card). Added 2026-06-30; analyze
          clean. SQL methods exercised in device QA per this file's convention.
    - [x] `getMarginMovers` (+ `MarginMoverResult` with pure-tested `margin` /
          `marginPercent`). **Decision (2026-06-30): current-cost approximation** —
          uses `product_variants.cost_price` (cost-at-sale isn't stored);
          null-cost variants excluded. Added 2026-06-30; analyze clean, 13 tests
          pass. Revisit once M4 lands real COGS / cost-at-sale.
    - [ ] `getFraudSummary` — **blocked:** reads Phase 2 / M1 (fraud engine),
          which is deferred under the current priority order. Defer with it.
17. [x] **Insights generator** — `lib/features/insights/`: pure
        `InsightsGenerator.generate(InsightsMetrics)` → ordered `List<Insight>`
        (deterministic template phrasing, works on web), fed by
        `InsightsRepository` (gathers via Task-16 `AiToolService` methods,
        permission-gated). Added 2026-06-30; 13 generator tests pass.
        **Note:** the LLM-rephrasing layer is deferred — template phrasing is
        the shipping implementation (robust + offline/web-safe); an optional LLM
        polish pass can wrap the generator later without changing the numbers.
18. [x] **Permissions** — `insights.view` wired end to end: `PermissionKeys`
        → `AppPermission.viewInsights` → both matrices (Owner auto, Branch
        Manager granted; Cashier/Inventory denied) → reports-module gate added to
        `PermissionService._moduleCodeForKey`. Matrix sync verified IN SYNC.
        (No new table/write → no new RLS; the underlying read queries already run
        under existing RLS on transactions/expenses/product_variants.)
19. [x] **Dashboard card** — `InsightsCubit` + reusable `InsightCard`
        (`DashboardCard` shell, `AppColors`, `Theme` text — no hardcoded styles).
        Self-hides when the role lacks `insights.view` or there's nothing to
        report, so it sits unconditionally on the dashboard. Replaced the old
        mock `ai_insights_card.dart` (deleted). Repo registered in `di.dart`.

**CHECKPOINT:** ✅ owner opens the app and sees a plain-language daily "what
changed + what needs attention" card, generated on-device, permission-scoped.
Code-verified (analyze clean, 83 tests pass); **on-device visual QA still owed**
(run the app on Owner + Branch Manager + Cashier to confirm show/hide + phrasing).

---

## Phase 4+ — remaining milestones (sequence, lower detail)

Detail these into their own task lists when you reach them. Order is dependency-
driven (see the roadmap's dependency graph).

20. [ ] **M3.1 Stock transfers** — `stock_transfers` + items tables (both sides),
        send/receive legs write `stock_ledger`, reconciliation → `transferMismatch`
        fraud rule.
21. [ ] **M3.2/3.3** Reorder points + lightweight forecasting → feeds insights.
22. [ ] **M4 Procurement intelligence** — auto-PO suggestions, supplier perf,
        landed cost/COGS (COGS also powers `NEGATIVE_MARGIN_SALE`).
23. [ ] **M5 Customers/CRM + loyalty** — new `customers` module, link to
        transactions/refunds, loyalty ledger.
24. [ ] **M6 Money** — reports overhaul, tax engine, accounting export, budgets.
25. [ ] **M-BIR — BIR compliance & invoice (CRITICAL, pre-commercial-launch)** —
        full spec in `UPSENSO_BIR_COMPLIANCE.md`. The legal gate before selling
        to any registered PH business. Highlights: rename the document to
        **INVOICE** (EOPT), all mandatory invoice fields + VAT breakdown +
        SC/PWD discounts, **per-device gapless sequential numbering** (offline-
        safe via `pos_devices` series), Accumulated Grand Total, X/Z readings,
        tamper-proof (reuses M1 audit chain), then eAccReg enrollment + TWG demo.
        Build the `pos_devices` model **together with** M7.1's device cap. Note:
        once accredited, major invoice-logic changes require **re-accreditation**.
26. [~] **M7.1 Subscription & limits** — spec in
        `UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md` (PHP pricing, entitlement
        layer, offline distributed-limit reconciliation). **Gateway is Google
        Play Billing, not GCash/Maya** — PayMongo retired 2026-07-24, see
        `UPSENSO_PLAY_BILLING.md`. Engine, migrations, edge functions, client
        flow and hardening are built; remaining work is activation + the
        `cloud_gate_enforced` flip (below).
27. [ ] **M7.2–7.4** multi-currency, hardware/integrations, push notifications.
28. [ ] **M8** (continuous) — delta-sync at scale + conflict UI, security/RLS
        audit, CI test gates, performance, web parity.

---

## 🚦 Pre-ship launch gate (do LAST, before any public/commercial release)

These are not features — they're the legal/trust requirements that must be in
place **before real users touch the app**. App stores also require them.

29. [ ] **M-LEGAL — Terms, Privacy & Data Privacy Act** (do last, before ship):
    - [ ] **Privacy Policy** (required by Google Play / App Store; explains what
          data is collected, why, retention, user rights).
    - [ ] **Terms of Service** — including the **provisional-invoice notice** from
          `UPSENSO_BIR_COMPLIANCE.md` §9.4 (UPSENSO docs are not BIR-official in
          provisional mode; businesses remain responsible for official receipts).
    - [ ] **Data Privacy Act (RA 10173)** compliance — you process personal data
          (employees, customers): lawful basis, consent where needed, security
          measures, breach-response plan; register with the **NPC** if/when you
          meet the thresholds (sensitive data / scale).
    - [ ] In-app **first-run consent / acceptance** of Terms + Privacy.
    - [ ] Confirm **business + BIR registration** is done *if* taking real
          payments at launch (see `UPSENSO_BIR_ACTION_PLAN`); free beta with the
          §9 non-official disclaimer needs no registration.

> This gate is independent of feature milestones — even a free beta with real
> users needs Privacy + Terms. Keep it as the final checklist before flipping the
> app public.

---

## Definition of done — applies to EVERY step above

From `CLAUDE.md` — a step isn't `[x]` until all hold:

1. PermissionKeys → AppPermission → AppFeature → role matrix → default matrix
   (`dart run tool/diff_matrices.dart` in-sync).
2. Module gate set; permission checks in Bloc/UseCase **and** GoRouter guard.
3. Server-side RLS enforces every write (UI hiding ≠ security).
4. Offline-first: local write → background sync; `sync_status` lifecycle; LWW;
   soft deletes.
5. Drift schemaVersion bumped + `onUpgrade` + Supabase migration with rollback
   (additive, non-destructive).
6. Every `catch (e, st)` logs with stack trace + graceful UI.
7. Reuses `lib/core/widgets/`; no hardcoded colors/styles/spacing.
8. Tests for critical paths; `flutter analyze` + `flutter test` green.
9. AI-queryable where relevant (branch-filtered, permission-scoped).

## 📌 Current position / session handoff

> **2026-08-01 — Audit gate split: log viewer drops to Starter. CODE COMPLETE,
> NO SUPABASE CHANGE, NO MIGRATION NEEDED.**
>
> `audit` was always a three-rung flag (`local|cloud|full`) but both
> `AppFeature.auditLogs` and `fraudAlerts` gated on `full`, so **Starter paid for
> a `cloud` rung that unlocked nothing** — its chain was backed up off-device and
> it still couldn't open it. Now:
>
> | Tier | flag | Audit log viewer | Unusual Activity |
> |---|---|---|---|
> | Free | `local` | — | — |
> | Starter | `cloud` | **✅ new** | — |
> | Growth | `full` | ✅ | ✅ |
>
> - `featureAllowed` splits the two cases: `auditLogs` → `auditRank != 'local'`,
>   `fraudAlerts` → `auditFull`. `requiredPlanFor` moves in lockstep
>   (`auditLogs → starter`), and `feature_plan_requirement_test` fails the suite
>   if the two ever disagree.
> - **No migration.** `plan_limits.feature_flags` already carried exactly these
>   values since the 2026-07-31 retune; only the client's reading changed, so
>   live tenants pick it up on their next entitlement sync.
> - Router guards and both nav builders already treated the two features
>   separately, so they needed no edit — the Audit Logs crown just became a
>   **Starter** crown on Free by itself.
> - Plan cards: Starter now reads "Audit log / Open every action in-app…";
>   Growth reads "Audit log & unusual-activity alerts / Everything in the log,
>   plus automatic warnings when voids, discounts or refunds look wrong".
>
> ⬜ On-device QA: confirm a Starter account opens Audit Logs with no crown and
> still sees a Growth crown on Unusual Activity.

> **2026-08-01 — Full subscription-limit enforcement. CODE COMPLETE, NO
> SUPABASE CHANGE. Analyze clean, 341 tests green (was 307).** Plan at
> `C:\Users\User\.claude\plans\iwamt-you-to-imoplement-stateless-kazoo.md`.
>
> **The bug that started it:** "Unusual Activity" navigated nowhere. The
> 2026-07-31 retune added `AppRoutes.fraud → AppFeature.fraudAlerts` to
> `routeEntitlementGuards` but left both nav builders rendering a plain,
> tappable item — on every tier below Growth it silently redirected to the
> dashboard. Fixed by making the nav rule explicit and testable.
>
> - **Plan badges in drawer + sidebar.** New `planLockFor()` +
>   `PlanLockBadge`. Rule: permission ✗ → hidden, module ✗ → hidden, plan ✗ →
>   **visible with the required tier badge**, tap opens the upgrade sheet.
>   `feature_plan_requirement_test` asserts `planLockFor` and `featureAllowed`
>   agree on every tier, so this class of bug can't come back silently.
> - **The one-month loophole is closed.** ₱499 once used to buy five permanent
>   branches: caps were checked on insert and never again. New
>   `EntitlementEnforcementService` + local-only `entitlement_locks` table
>   (**Drift 59 → 60**) keeps exactly N active and locks the excess read-only.
>   Nothing is ever deleted; upgrading releases every lock automatically. The
>   branch open in POS is always in the default active set — a downgrade can
>   never stop a till mid-shift.
> - **Offline verification window.** New `unverified` status keeps a paid tier
>   (and cloud) alive for 14 days / 30 annual past `current_period_end` when we
>   simply can't reach the server, anchored on `last_server_sync_at`. Play
>   renews silently, so without it a merchant who'd been charged got downgraded
>   for having no signal. Documented in §7.4 since forever, never coded.
> - **Devices actually say something.** `capReached` was set and never
>   rendered; now `PlanNoticeService` explains it with Manage-devices, sync
>   re-verifies registration on the entitlement tick (so a remote revoke lands
>   without a restart), and `touch_device` finally gets called so `last_seen_at`
>   is real. Wired the dead `UpgradeMoment.secondDevice`.
> - **Branch-create correctness:** typed `AddBranchResult` (cap vs permission
>   denial were both bare `null`), local rollback on a server cap rejection
>   instead of a row retrying forever, usage recompute after create, and
>   `countForBusiness` now excludes pending-delete rows — deleting a branch used
>   to free no headroom until the delete synced, i.e. offline, never.
> - **AlertPage was a dead end on mobile** (stacked sub-page, no back control) —
>   now owns an `AppSubPageBar`. Audit Logs was opening via `_pushFullPage`,
>   bypassing GoRouter and its new guard entirely on mobile; routed properly.
>
> ⬜ **REMAINING — two things, both yours:**
> 1. **On-device QA on Android** (see the plan file's Verification section).
> 2. **The cloud gate is still FALSE in prod**, so all of the above is a UX gate
>    on an unsigned local cache. Runbook written:
>    `docs/UPSENSO_CLOUD_GATE_CUTOVER.md`. Until you flip it, the paywall is
>    advisory — this work is not "enforcement" without it.

> **2026-08-01 — Billing Plans tab overhaul. CODE COMPLETE, NO SUPABASE
> CHANGE. Analyze clean, 266 tests green.** Plan at
> `C:\Users\User\.claude\plans\in-subscription-and-billing-snuggly-bachman.md`.
> Four things, all client-side:
> - **Fixed the stale "Price locked at ₱499/mo" chip.** `grandfathered_price`
>   outlives the subscription on the `subscriptions` row, so a lapsed Growth
>   tenant fell back to Free and the Free card inherited their ₱499. The card no
>   longer decides: `BillingPlansTab._lockedPriceFor` shows a lock only when the
>   tenant is in a paying status, on that exact tier, on a paid tier, and the
>   locked figure is genuinely *below* today's list price. **The SQL was always
>   right** (a plan change re-locks at list) — this was display-only.
> - **Subscribed = summary, not a ladder.** `active`/`past_due` on a paid tier
>   now renders one `CurrentPlanCard` (tier, price, renewal date, benefits,
>   usage meters) with **Manage subscription** deep-linking to Play's
>   subscriptions screen, and the cards behind a **Change plan** reveal (Free
>   filtered out there). Renders offline from the entitlement cache.
> - **Restore is fully automatic — the button is gone.** Startup, page open,
>   resume, connectivity return, backoff retry. `load({restorePurchases})` lets
>   the grant-driven reload skip it explicitly. Manual fallbacks: pull-to-refresh
>   and the stuck-purchase dialog's Try again.
> - **"Check billing setup" deleted end to end** (button, cubit method, state
>   fields, remote-DS call, `BillingProbeCheck`). The edge function's
>   `{"probe": true}` branch stays — it's support-only; the curl is now in
>   `UPSENSO_PLAY_BILLING.md`.
> - Plan cards now explain themselves: a plain-language gloss per capability
>   row, a ₱/day line on paid tiers, and Free naming the two things it does not
>   give you. All derived from `plan_limits` in one shared `plan_benefits.dart`.
> - **Drift schema 58 → 59** — additive nullable `entitlement_cache.billing_period`
>   (the summary card must say "/month" vs "/year" offline; `get_my_entitlement()`
>   already returned it). Rollback: harmless to leave; v58 never reads it.
> - ⬜ **REMAINING — on-device QA on Android** (`--dart-define-from-file=flavors/dev.json`),
>   per the plan's verification section: 58→59 upgrade over a previous install
>   with no data loss and Billing still painting in airplane mode; buy Starter as
>   a licence tester → grid collapses to the summary; Manage subscription opens
>   Play and returning refreshes without a duplicate restore; cancel in Play →
>   summary survives `past_due`, then falls back to the ladder once lapsed with
>   **no ₱499 chip on Free**.

> **2026-07-31 — DUPLICATE-SIGNUP BUG: root-caused, cleaned up, and fixed.
> BOTH MIGRATIONS APPLIED TO PROD.** Found while applying the plan retune: prod
> held **8 identical "Cruz Store" businesses**, all owned by one auth user,
> created within 100 seconds on 2026-07-26.
>
> **Root cause (proven).** `business_repository_impl.createBusiness` minted a
> fresh `Uuid().v4()` *inside* the method, so every retry of a failing signup
> created a whole new server-side business. The `businesses` INSERT commits on
> its own; the flow then died before branches/roles/receipt_settings/users
> landed, and the catch only marked the LOCAL row sync-failed — it never reused
> the id nor cleaned up the remote orphan. 8 taps → 8 orphans. Each carried only
> the business row + trigger output (subscription, subscription_events,
> business_modules, 16 provisioning audit rows).
> **The precipitating error itself is NOT recoverable** — Postgres logs from
> 2026-07-26 are past retention. Ruled out by direct inspection: branches RLS
> (all 4 policies pass), table grants, createBranch payload vs schema, triggers/
> constraints on branches, and RPC arity. The retry gap pattern (29s then 3s,
> 17s, 20s, 21s, 2s, 8s) reads as a timeout followed by impatient re-taps.
>
> **Blast radius:** `getBusinessByOwner` used `.maybeSingle()`, which THROWS on
> >1 row — that account could no longer start online or sync at all.
>
> - `20260731131524_cleanup_orphan_businesses.sql` — deleted the 8. Asserts each
>   target holds no real data first. **Gotcha worth remembering:** the
>   `log_permission_change()` trigger on `business_modules` /
>   `user_permissions` / `branch_permissions` INSERTs into `audit_logs` on
>   DELETE, and `audit_logs.business_id` is FK'd NO ACTION — so letting them go
>   via the businesses cascade fails with an FK violation against the row being
>   deleted. Those three must be drained explicitly *before* the parent.
> - `20260731131554_atomic_onboarding.sql` — (1) `my_business_id()` now ORDER BYs
>   (its `LIMIT 1` was non-deterministic for a multi-business owner, and it feeds
>   `has_permission()`'s owner fast-path + `effective_limits()`); (2) unique index
>   `businesses_owner_id_key`; (3) `create_business_onboarding()` does business +
>   branch + template + owner user row in ONE transaction, idempotent per owner.
> - Client: one RPC call replaces four round-trips; `BusinessBloc` holds stable
>   business/branch ids across retries; the local Drift inserts became
>   `insertOnConflictUpdate` (a retry reusing ids used to hit a UNIQUE
>   constraint — caught by the new test); `getBusinessByOwner` orders + limits.
>   `SyncService._handlePendingUpload` now also goes through the atomic RPC —
>   it used to push a bare business row, i.e. the same half-built tenant via the
>   offline door. Dead partial-provisioning methods removed from the remote DS.
> - Verified post-apply: 1 business remains; 0 owners with duplicates; a
>   duplicate INSERT is rejected by the index; the previously-bricked account now
>   resolves to 0 businesses so it routes cleanly to onboarding.
> - Tests: `test/features/business/business_repository_impl_test.dart` (4 new) +
>   `tool/onboarding_checks.sql`. Suite 210 green, analyze clean.
> - ⬜ Remaining: on-device end-to-end signup QA (kill the network mid-signup and
>   confirm zero partial rows land, and that retrying doesn't duplicate).

> **2026-07-31 — M7.1 plan retune. CODE COMPLETE, MIGRATION APPLIED TO PROD.**
> Plan at `C:\Users\User\.claude\plans\lively-bubbling-sedgewick.md`.
> Product decision: **Growth = every feature unlocked** (unlimited devices,
> 5 branches, 15 seats), **Starter = 1 branch / 3 seats / 3 devices**, Free
> unchanged. Prices unchanged (₱199/₱499) → **no Play Console work**,
> `play_product_map` untouched.
> - `20260731124330_plan_limits_retune.sql` edits `plan_limits` **v1 in place**,
>   applied via MCP `apply_migration` 2026-07-31 (user-approved) and verified
>   read-only. It opens with a guard that ABORTs if any **provider-backed** sub
>   is inside a live window.
> - **Prod tenant reality found while applying** (contradicted the "no users"
>   assumption, but did not change the decision): 9 businesses / 9 subs —
>   8 × "Cruz Store" are the 2026-07-26 phantom-trial duplicates (no provider,
>   0 txns, 0 employees, trials expire 2026-08-09) and 1 × "Heaven brew" is a
>   `google_play` license-tester purchase that lapsed 2026-07-31 12:34 UTC.
>   None were harmed: live subs resolve limits from their **pinned
>   entitlement_snapshot**, not from `plan_limits`, so the UPDATE cannot change
>   what anyone was sold. Verified post-apply: Heaven brew (lapsed) now resolves
>   the new free row (`audit: local`); Cruz Store (trialing) still resolves its
>   old pinned snapshot (`cloud_audit: true`, 2 devices) — proof the snapshot
>   mechanism holds.
> - ⬜ **Cleanup candidate (not done, needs a decision):** the 8 phantom-trial
>   Cruz Store rows are junk test tenants carrying the old flag shape. Left
>   untouched deliberately — deleting business data is not a migration's call.
> - `cloud_audit` (bool) → **`audit` (`local`|`cloud`|`full`)**. The chain
>   records on every tier; only `full` (Growth) sells the Audit Logs viewer +
>   Fraud dashboard, now enforced via `EntitlementService.featureAllowed` +
>   `routeEntitlementGuards`.
> - Closed two flags that were **read but never acted on**: `reports: full` now
>   gates the Branch Comparison tab + report PDF/Excel export; the audit flag
>   now gates the viewer. Before this, Starter silently got everything.
> - `audit_logs` added to the always-free Data Export — the compliance guard
>   rail that makes the viewer gate defensible (§4.7 + BIR retrievability).
> - `UpgradeMoment` prompts had **zero call sites**; branchCap, seatCap and
>   lockedModule are now wired.
> - REMAINING: apply the migration (approval gate), then on-device QA of the
>   Starter-shaped tier per the plan's verification section.

> Live status so any session (or a fresh Claude one — no memory between sessions)
> resumes exactly here. **Last updated: 2026-07-03 (later session) — M1 (audit
> chain + fraud engine) CODE COMPLETE + BOTH MIGRATIONS APPLIED to prod, per
> the hardened plan
> (`C:\Users\User\.claude\plans\check-upsenso-execution-sequence-md-and-majestic-crystal.md`).
> Phases 0–2 built; analyze clean; 177 tests green.
> `20260703000002_audit_chain_columns.sql` + `20260703000003_fraud_flags.sql`
> applied 2026-07-03 via `npx supabase db query --linked --file` (user-approved)
> and verified read-only: chain columns/index/RPCs present; fraud_flags fully
> shaped (prod had an EMPTY AI_CONTEXT-era fraud_flags scaffold — adopted
> in place via ALTERs, legacy permissive `fraud_admin_only` policy dropped);
> 4 new policies + freeze trigger live; role grants match the client matrices
> exactly (Owner: all 4 codes; BM: fraud.* only; Cashier/Inventory: none;
> ×3 businesses). REMAINING: (1) on-device QA — tamper a local row → Verify
> integrity reports it; refund abuse on a test business → flags appear; BM
> cannot resolve a flag naming themselves (live RLS); cashier sees no fraud
> nav; (2) commit (nothing committed yet — the whole M1 diff is in the
> working tree).**

> **2026-07-28 — M7.1 Play Billing hardening. CODE COMPLETE, NOTHING APPLIED TO
> PROD.** `flutter analyze` clean, 195 tests green (72 in `test/features/billing/`).
> Full detail in `UPSENSO_PLAY_BILLING.md`; plan at
> `C:\Users\User\.claude\plans\so-iwant-you-to-splendid-bonbon.md`.
>
> Fixed the reported bug — a Starter→Growth upgrade granted correctly but still
> raised a blocking "we couldn't confirm your purchase" dialog, because Play kept
> returning the replaced token and its 409 was read as charged-but-not-granted.
> Server now returns `play_superseded`; client treats it as silent.
>
> Also closed, in the same path: purchase-token hijack (Google's
> `obfuscatedExternalAccountId` is now compared against `sha256(business_id)` —
> previously any valid unbound token could be claimed by whoever presented it
> first); client-controlled plan id (`sub.productId ?? productId` fallback let a
> Starter buyer claim Growth); post-upgrade silent downgrade (stale-token guard on
> `apply_play_subscription`); permanently-dropped RTDNs (ledger row was written
> before processing, so a retry was answered "duplicate"); RTDN forgery (OIDC push
> auth replaces the URL-query secret that was logged in plaintext); unbounded
> verify/restore loop; unthrottled probe that could exhaust the shared Google
> quota for every tenant.
>
> **REMAINING, in order:**
> 1. Apply `20260728000001_play_billing_hardening.sql` statement-by-statement
>    (**never `supabase db push`**).
> 2. Deploy both edge functions — `verify-play-purchase` with JWT,
>    `google-play-rtdn` with `--no-verify-jwt`.
> 3. RTDN auth cutover: set `PLAY_RTDN_PUSH_SA` + `PLAY_RTDN_ALLOW_LEGACY=true`,
>    run `gcloud pubsub subscriptions update --push-auth-service-account`, confirm
>    OIDC deliveries, then turn legacy off and delete the shared secret.
> 4. **Flip the cloud gate** — `20260728000002_enable_cloud_gate.sql`, applied
>    SEPARATELY and last. Verified read-only against prod 2026-07-28:
>    `cloud_gate_enforced = false` (confirmed), 8 businesses `trialing` until
>    **2026-08-09** (unaffected today, they lapse on that date), 1 `lapsed`
>    license-tester account that loses cloud writes immediately. Nobody is
>    mid-grace. Until this flips, the paywall is advisory — `has_cloud_access()`
>    returns TRUE for everyone and the unsigned local `entitlement_cache` is the
>    only gate. Rollback is a one-row UPDATE.
> 5. Run `tool/billing_rls_checks.sql` §7–§11 against a preview branch — it has
>    never been run.
> 6. Live E2E with a Play license tester: free → Starter → Growth → annual →
>    downgrade → cancel → refund. The Starter→Growth leg must complete with no
>    dialog.
> 7. Commit (nothing committed yet — the billing diff is in the working tree
>    alongside the M1 diff).

### Active priority order
**M2 (AI insights) → M5 (CRM) → M1 (fraud+audit, deferred) → M-BIR → M-LEGAL → ship.**
(See the "Priority override" section near the top for the rationale.)

### Done
- ✅ All planning/spec docs (on `main`).
- ✅ **M2 Task 16 analytics methods** — `getSalesTrend`, `getApprovedExpenseTotal`,
  `getTopProducts`, `getLowStockCount`, `getMarginMovers` in
  `lib/features/ai_assistant/services/ai_tool_service.dart`. Tests pass.
  Committed on `main`. Only `getFraudSummary` remains (deferred with M1).
- ✅ **M2 Tasks 17 + 18 + 19 — Proactive AI Insights. COMMITTED to `main`.**
  - **17 (generator):** `lib/features/insights/` — pure `InsightsGenerator`
    + `InsightsMetrics` + `Insight` entity; `InsightsRepository` gathers via
    `AiToolService`, permission-gated at the repository layer.
  - **18 (permission):** `insights.view` fully wired — `PermissionKeys` →
    `AppPermission.viewInsights` → both matrices (branchManager + above = true,
    cashier/inventory = false). `_adminMatrix` picks it up via `PermissionKeys.all`.
  - **19 (card):** `InsightsCubit` + `InsightCard` on the dashboard (self-hiding
    when denied or empty); old mock `ai_insights_card.dart` deleted; repo in DI.
  - **Bug fix (same commit):** `PermissionService.loadEnabledModules` now always
    sets `_moduleStates` (even to `{}` when no rows), so the "absent = enabled"
    path runs instead of the null-guard fail-closed path that was blocking the
    `reports` module (and therefore `insights.view`) for businesses with no
    `business_modules` rows.
  - **Gates:** `flutter analyze` clean, `flutter test` 83 pass, visual QA done.

### M5 — CRM foundation — ✅ DONE (code + both migrations + gaps + QA all confirmed)
Full customers module built end-to-end, mirroring the procurement/suppliers
pattern. Reuses the **existing `crm` module** (already seeded + enabled in the
Supabase `modules` catalogue — no new module invented).
- **Permissions:** `crm.view` / `crm.manage` / `nav.customers` wired through
  `PermissionKeys` → `AppPermission` (viewCustomers/manageCustomers) →
  `AppFeature.customerDirectory` (module `crm`) → both matrices (Owner all;
  Branch Manager view+manage+nav; **Cashier `crm.view` only** so they can attach
  an *existing* customer at the till but not quick-add; Inventory none) +
  `_moduleCodeForKey` `crm` case.
- **Drift (schemaVersion 51→52):** new `customers` table + `customers_dao`
  (mirrors suppliers), nullable `transactions.customer_id` FK, onUpgrade
  (createTable + addColumn + 2 indexes). `build_runner` run.
- **Supabase migration WRITTEN + APPLIED (2026-07-02, user ran it directly in the
  SQL Editor on the live prod project `dmhyfezuravbjpoxjesb`):**
  `supabase/migrations/20260702000001_crm_customers.sql` (customers table + RLS
  [tenant SELECT, `crm.manage`-gated INSERT/UPDATE, no DELETE] + transactions
  `customer_id`). **Confirmed working** — prior `[SYNC] Customer ... FAILED:
  PGRST205 (Could not find the table 'public.customers')` errors are gone and
  customer push/pull sync succeeds.
- **Feature `lib/features/crm/`:** entity + `CustomerStats`/`CustomerPurchase`,
  `ICustomerRepository` + `CustomerRepository` (local-first, audit-logged via new
  `customerCreated/Updated/Archived` audit types), `CustomerRemoteDs`,
  `CustomerCubit`/state + `CustomerDetailCubit`, customers list/detail pages,
  form sheet, `CustomerCard`, and the checkout **`CustomerInlinePicker`** — an
  inline typeahead (no bottom sheet): type in the field and matching customers
  appear instantly below it. Three paths from one field: (1) tap a match →
  **link** the saved customer (customer_id + name, builds history), (2) just
  leave the typed text → **name only** (customer_name, no record — everyone incl.
  cashiers), (3) **Save "X" as a customer** inline row (`crm.manage`-gated, opens
  a tiny name+phone quick-add prefilled from the query). `CustomerSelection`
  (`customer_selection.dart`) carries record / nameOnly / walkIn and is emitted
  via `onChanged`; a linked selection shows a "purchase history will be tracked"
  confirmation.
- **POS:** checkout free-text field replaced by the inline picker in **both**
  checkout screens — the **live** `products/checkout/product_checkout_page.dart`
  (used by the POS terminal, held sales, product cart) **and** the legacy/unused
  `pos/.../checkout_payment_page.dart`. Widget:
  `crm/.../widgets/customer_inline_picker.dart`. A saved-customer sale stores
  `customer_id` + `customer_name`; a name-only sale stores just `customer_name`.
  Purchase history = completed sales where `customer_id = X` (new
  `TransactionsDao.watchByCustomerId`).
- **Wiring:** DI (`CustomersDao`/`CustomerRemoteDs`/`ICustomerRepository` + into
  `SyncService`), `SyncService._syncCustomers` push + pull + clearAll + pending
  counts, routes (`/more/customers` [+detail]) with permission+module route
  guards, router Branch 12, sidebar + mobile More nav (gated by
  `nav.customers` + `crm` module).
- **Gates:** `flutter analyze` clean; **full `flutter test` green.**

### Post-commit QA prep (2026-07-02) — two real gaps found and closed
Preparing on-device QA surfaced two things that would have made the QA checklist
undoable / the permission model dishonest. Both fixed, tested, and verified before
any manual QA ran:
1. **`crm` module was missing from Module Management** — an Owner had no way to
   toggle Customers off/on (`isModuleEnabled` treats an absent module as enabled,
   so it silently worked, but the toggle UI itself didn't exist). Added a `crm`
   `_ModuleInfo` entry to `_kModules` in
   `lib/features/settings/presentation/module_settings_page.dart`.
2. **`crm.view` was a dead permission** — nothing enforced it; the checkout
   customer search was open to every role regardless of the matrix. Gated the
   existing-customer suggestions (search results + "no match" hint +
   "save as customer" row) in `CustomerInlinePicker` behind `can(PermissionKeys.crmView)`
   — the name-only typing path stays open to everyone. Since `can()` already
   resolves `crm.view` through the `crm` module gate, disabling the module also
   hides checkout suggestions for free.
- **New tests** (both green, `flutter analyze` clean):
  - `test/core/permissions/crm_permissions_test.dart` — locks
    `crm.view`/`crm.manage`/`nav.customers` per role against both
    `DefaultPermissionMatrix` (offline) and `RolePermissionMatrix` (online), and
    asserts the two stay in sync.
  - `test/features/crm/customer_inline_picker_test.dart` — widget-level: `crm.view
    =false` shows zero suggestions (name-only still emits); `crm.view=true,
    crm.manage=false` (cashier) shows matches but no save row, tap-to-link works;
    `crm.manage=true` shows the save row.
- **Full suite: 109 tests, all green** (was 94; +12 permission-matrix +
  3 widget-gating tests).

3. **[SEVERE] `crm.view`/`crm.manage`/`nav.customers` were never seeded server-side**
   — user's own question ("did you consider employee accounts have default
   permissions that can be overridden?") caught this. `20260702000001_crm_
   customers.sql`'s RLS policies call `has_permission('crm.manage')`, but no
   migration ever inserted `crm.view`/`crm.manage`/`nav.customers` into
   Supabase's `permissions` catalogue (confirmed: only `20260609000001`,
   `20260611000001`, and `20260627000007` ever `INSERT INTO permissions`, none
   mention `crm`). Consequence: `has_permission('crm.manage')`'s `role_allow`
   branch can never resolve a `permission_id` for a code that doesn't exist, so
   it always falls through to `false` for every non-owner — **only the literal
   `businesses.owner_id` account can write to `customers` online right now.** A
   Branch Manager's create/edit passes every client-side check (both
   `RolePermissionMatrix` and `DefaultPermissionMatrix` say they're allowed),
   writes succeed locally (offline-first), then **silently fail to sync** with
   an RLS-denied Postgrest error. Per-employee overrides for crm.* would also be
   unsettable (`set_employee_permission_override` resolves the same
   nonexistent `permission_id`).
   - **Client fix (done):** added a "Customers" `_PermGroup` (`crm.view` /
     `crm.manage`) to `_kGroups` in
     `lib/features/employees/presentation/pages/employee_permissions_page.dart`
     — previously CRM had no entry at all, so no admin could set a per-employee
     override for it even through the UI. Mirrors the existing Suppliers group;
     no `nav.customers` entry (nav keys are never listed — they resolve via the
     access key, matching the established convention).
   - **Server fix WRITTEN + APPLIED (2026-07-03, user ran it directly in the SQL
     Editor on the live prod project `dmhyfezuravbjpoxjesb`):**
     `supabase/migrations/20260703000001_seed_crm_permissions.sql` — seeds the 3
     codes into `permissions`, wires `role_permissions` (Business Owner +
     Branch Manager full; Cashier `crm.view` only; Inventory Staff none, matching
     the client matrices), wires `business_template_role_permissions` so new
     businesses inherit it, and recomputes `effective_permissions` for existing
     employees. Modeled directly on the two prior instances of this exact class
     of bug: `20260627000007_seed_recipe_ingredient_permissions.sql` and
     `20260615000001_wire_procurement_role_permissions.sql`. **Independently
     verified live 2026-07-03** via `npx supabase db query --linked` (the
     Supabase CLI is already authenticated + linked to `dmhyfezuravbjpoxjesb` in
     this environment — no access token/DB password needed, just `npx supabase
     <cmd>`): all 3 codes present in `permissions`; `role_permissions` correct
     across all 3 businesses on this project — Business Owner + Branch Manager
     get all 3 codes, Cashier gets `crm.view` only, Inventory Staff confirmed
     **zero** CRM grants (3 role rows, 0 matching grants).
- These fixes are committed (`4923d68`) and pushed to `origin/main` (`d02db20`).

### Next action
- ✅ **Supabase migration applied** 2026-07-02 — `public.customers` exists on
  prod, RLS active, customer sync push/pull confirmed working end-to-end.
- ✅ **Client-side permission/module gaps (#1, #2) fixed + test-locked** 2026-07-02.
- ✅ **Client-side employee-permission-editor gap (#3) fixed** 2026-07-02 —
  Customers group added.
- ✅ **`20260703000001_seed_crm_permissions.sql` applied** 2026-07-03 by the user
  directly in the SQL Editor, then **independently verified live** the same day
  via the Supabase CLI (see below) — all row counts correct across all 3
  businesses on the project.
- ✅ **On-device manual QA — confirmed working by user** 2026-07-03 (checklist
  was in the session's plan file,
  `C:\Users\User\.claude\plans\steady-launching-puzzle.md`, Part 3). User
  confirmed the app works end-to-end after both migrations, including the
  non-owner checkout scenario that gap #3 had broken.
- ✅ **Committed** (`4923d68`) and **pushed** to `origin/main` (`d02db20`)
  2026-07-03.

**M5 — CRM foundation is DONE.** Code, both Supabase migrations, permission
gaps, tests, and manual QA all confirmed. Per the priority order at the top of
this doc, the next milestone is **Phase 1 + 2 — M1: audit chain + fraud engine**
(previously deferred so M2/M5 could ship first).

### M1 HOTFIX (2026-07-03) — audit-chain restart false-positives (FIXED, client-only)
First on-device QA raised **46 false CRITICAL AUDIT_TAMPER flags** + a stuck
sync queue — no real tampering. Root cause: genesis-resume restarted a
**restored** device_uid's chain at seq 1 when the server head came back null
(wiped web IndexedDB + surviving localStorage uid), colliding with the synced
chain; the collision was then misclassified as tamper. All client-only fixes
(no migration), analyze clean, full suite **182 green**:
- **F1** `_resolveResume` now rotates to a fresh uid only when a *restored*
  uid can't confirm a server head; a freshly-minted uid still starts genesis
  (added `DeviceIdentityService.wasRestoredFromStorage`).
- **F2** `AuditLogService.reconcileConflictedTail` re-chains a conflicted
  unsynced tail past the server head (no audit loss); wired via
  `SyncService.onChainConflict`.
- **F3** `AUDIT_TAMPER` is now **verifier-only** — the push-conflict scan is
  removed (a sync conflict is not a fraud signal; the cryptographic verifier
  is the reliable tamper signal). *[user decision]*
- **F4** engine clamps all rule windows to the **M1-install cutoff** (earliest
  chained audit row) so the first sweep ignores pre-M1 historical noise.
  *[user decision]*
- **F5** the 46 false server flags **deleted + verified** (only 1 real
  historical EXCESSIVE_REFUNDS remains, which F4 now stops re-raising).
- **Local web instance:** clear browser site data for a clean slate (or let
  F2 self-heal + F3 stop regeneration on next sync). Dev-only step — prod
  users are covered by F2.

**Supabase CLI works in this environment** (discovered 2026-07-03) — `npx
supabase <cmd>` is already authenticated and linked to `dmhyfezuravbjpoxjesb`
(the `supabase/.temp/` link state + some cached auth persist here; no access
token or DB password needs to be supplied). Prefer `npx supabase db query
--linked "<sql>"` for read-only checks going forward instead of asking the user
to paste queries into the dashboard. Still **ask before anything that writes**
(`db push`, `migration up`, etc.) — same rule as before, this only changes how
verification happens, not the apply-migration approval gate. Note:
`supabase migration list` shows the CLI's own tracking table doesn't have rows
for `20260702000001`/`20260703000001` (both `remote: ""`) because pasting SQL
into the dashboard bypasses that bookkeeping table — this is a cosmetic
tracking gap, not a sign the migrations didn't apply (confirmed applied via
direct data queries instead).
- ⬜ Backlog within M5: loyalty (separate `loyalty` module), thread
  `customer_id` through drafts + the AI checkout path, AI "top customers" tool.
- ⬜ Backlog within M2: optional LLM-rephrasing layer; `getFraudSummary` (waits
  on M1 fraud engine).

**Fraud false-positive incident #2 (2026-07-03, later the same day)** —
investigated, **not yet fixed**. After refund stress-testing, five alert types
fired; prod queries proved the integrity/orphan/clock-reversal ones are false
positives (refund audit rows exist server-side; chains are seq-complete; the
"clock moved backwards" is a `reconcileConflictedTail` transplant artifact;
two concurrent instances shared one device_uid; server `fraud_flags` is back
to 0 rows — flag sync not landing). Full evidence + the P0→P2 fix plan
(mirror-freshness gate, audit outbox, hash_version v2, confirmation pipeline,
branch scoping for "All branches", devices-table normalization) live in
**`docs/UPSENSO_FRAUD_FALSE_POSITIVE_FIX_PLAN.md`** — start there; next action
is P0 (after committing the M1 working tree).

### Repo/branch state
- M2 + M5 are both on `main` as of commit `971e8ae` (2026-07-02). `main` is
  **7 commits ahead of `origin/main`** — **not pushed** yet.
- **Uncommitted working-tree changes on top of `971e8ae`:** the three gap-fixes
  (`module_settings_page.dart`, `customer_inline_picker.dart`,
  `employee_permissions_page.dart`) + two new test files
  (`crm_permissions_test.dart`, `customer_inline_picker_test.dart`) + one new
  **unapplied** migration (`20260703000001_seed_crm_permissions.sql`) + this
  doc. Awaiting explicit go-ahead to commit and to apply the migration.
- Working rule: **never `git push` / commit without an explicit green light** from
  the user.

### Environment note for future sessions
- This local Windows session **DOES** have the Flutter SDK → you CAN run
  `flutter analyze` / `flutter test` / `build_runner` here. (Earlier remote
  sessions could not — if a future session is remote with no SDK, fall back to
  write+self-review and say so honestly; never claim tests passed when not run.)
  Note: `dart run tool/diff_matrices.dart` can't run via plain `dart` (it imports
  `package:flutter/foundation`); verify matrix sync via `flutter test` instead.
