# UPSENSO — Product Roadmap to "All-in-One Smart Business Platform"

> Status: **active plan — trimmed to remaining work (updated 2026-07-06).**
> The single sequenced plan from today's codebase to the full product vision:
> one platform where an SMB runs their whole business — POS, inventory,
> procurement, expenses, people, customers, money — with **offline-first**
> operation and a **tamper-evident audit chain + fraud detection** woven through
> it. Completed milestones have been removed from the active plan and summarized
> under "Already shipped" below.

## How to read this

- Remaining work is grouped into **Milestones**. Each is independently shippable
  and ordered by dependency + value. **Milestone numbers are stable** (other docs
  — `CLAUDE.md`, the execution sequence, the subscription design — cite them), so
  shipped milestones are removed but survivors keep their original M-numbers.
- Every feature carries its **mandatory wiring** per `CLAUDE.md`:
  PermissionKeys → AppPermission → AppFeature → both matrices → module gate →
  PermissionService/guards → offline/sync → tests.
- ✅ done · ⚠️ partial · ❌ missing — current state as of this plan.
- The **live, active task order** (including the M-BIR and M-LEGAL launch gates)
  lives in `docs/UPSENSO_EXECUTION_SEQUENCE.md`. This doc is the *dependency*
  reference; that one is *what to do next*.

---

## ✅ Already shipped (no longer active roadmap items)

- **M1 — Trust & Integrity** (tamper-evident audit chain + fraud detection
  engine) — **shipped in `v1.5.0`.** Per-(business, device) SHA-256 hash chain on
  `audit_logs` with a `AuditChainVerifier` + "Verify integrity" action, and a real
  `fraud_flags` engine (10 deterministic rules) feeding the `alert` UI. Spec
  retained in `docs/UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md`; false-positive
  hardening tracked in `docs/UPSENSO_FRAUD_FALSE_POSITIVE_FIX_PLAN.md`.
- **M5.1 + M5.2 — Customers & CRM** (customer directory + purchase history,
  offline-first, soft-delete, RLS-enforced, reuses the `crm` module) — **shipped.**
  Only **loyalty (M5.3)** remains, kept below as the sole open M5 item.
- **M2 — AI proactive insights — built, then deliberately removed.** The insights
  digest/dashboard card was implemented and then removed from the app (no
  `insights/` feature folder remains). It is **not** a pending item — do not
  re-add it without a fresh product decision. The reactive on-device **AI
  assistant** (NL query + transaction creation) is a separate feature and remains
  fully in place.

---

## Where we are today (baseline)

**Built & real:** POS/checkout, sales/refunds (with two-step approval),
products/variants/categories (+ multi-barcode & unit support), inventory + stock
ledger, recipes/ingredients, procurement (PO → receipt), expenses (with
approval), employees + per-employee permission overrides, role-specific
dashboards, **tamper-evident audit chain + fraud detection engine (M1)**,
**customers/CRM directory + purchase history (M5.1/M5.2)**, on-device AI
assistant (NL query + transaction creation), settings/onboarding/notifications/
drafts. RBAC + module gate is mature (server-side RLS enforcement).

**Promised but not real:**
- ⚠️ Reports — still a single page (M6.1 overhaul pending).
- ❌ Stock transfers between branches — permissions + audit action exist; **no
  table, no feature** (M3.1).
- ❌ Reorder automation & demand forecasting (M3.2 / M3.3).
- ❌ Procurement intelligence — auto-PO, supplier performance, landed cost/COGS
  (M4).
- ❌ Loyalty (points / tiers) — directory + history shipped; **loyalty ledger not
  built** (M5.3).
- ❌ Accounting/tax export, budgets (M6.2–M6.4).
- ❌ Subscription/billing — the only "subscription" in code is Dart
  `StreamSubscription`. Nothing exists (M7.1).
- ❌ Multi-currency, hardware/integrations, push delivery (M7.2–M7.4).

The milestones below close every one of these, in order.

---

# Milestone M3 — Inventory depth (multi-branch operations)

**Goal:** finish inventory as a real multi-branch system.

- **M3.1 Stock transfers between branches** — close the existing stub
  (`transferStockBetweenBranches` / `approveStockTransfer` permissions + audit
  action already exist; no table/feature). New `stock_transfers` +
  `stock_transfer_items` tables (Drift + Supabase), each leg writing the
  `stock_ledger` (`sourceType='transfer'`) on send and receive. Receiving leg
  reconciliation feeds a `transferMismatch` fraud rule (extends the shipped M1
  engine).
- **M3.2 Reorder points & low-stock automation** — per-variant/branch reorder
  level + safety stock; surfaces low-stock on the dashboard and in reporting.
- **M3.3 Demand forecasting (lightweight)** — moving-average / seasonal-naive
  projection from `stock_ledger` sales history → "days of cover" + suggested
  reorder qty. Deterministic, on-device. Feeds M4 auto-PO suggestions.
- **Permissions:** reuse inventory keys; add `inventory.transfer` enforcement
  server-side (RLS) to match the client permission.

**Exit criteria:** stock moves between branches with full ledger traceability and
mismatch detection; the app warns before stockouts.

---

# Milestone M4 — Procurement intelligence

**Goal:** make purchasing proactive, building on existing PO/receipt flow.

- **M4.1 Auto-PO suggestions** — generate draft POs from M3.3 forecasts +
  reorder points, grouped by supplier. Owner reviews → existing PO approval flow.
- **M4.2 Supplier performance** — lead-time, fill-rate, price-trend per supplier
  from `purchase_orders` + `goods_receipts`. Feeds supplier selection.
- **M4.3 Landed cost / cost history** — track unit cost over time from receipts;
  powers a `NEGATIVE_MARGIN_SALE` fraud rule (extends M1) and margin analytics
  (M6).
- **Permissions:** reuse `procurement.*`.

**Exit criteria:** the app suggests what to reorder, from whom, at what expected
cost — owner just approves.

---

# Milestone M5 — Loyalty (remaining CRM item)

> M5.1 (customer directory) and M5.2 (purchase history) are **shipped** — see
> "Already shipped" above. Only loyalty remains.

- **M5.3 Loyalty (points / tiers)** — configurable points-per-spend, redemption
  at POS. Offline-first accrual; LWW-safe ledger (`loyalty_ledger`).
- **New module:** separate `loyalty` module in `business_modules` + settings
  toggle (kept distinct from the shipped `crm` module).
- **Permissions:** `loyalty.manage`, `nav.loyalty`; AppFeature; both matrices; RLS.

**Exit criteria:** owner can reward repeat business — all offline-capable.

---

# Milestone M6 — Money: accounting, tax & budgets

**Goal:** make UPSENSO the system of record for the business's finances.

- **M6.1 Reports overhaul** — replace the single reports page with: P&L,
  product profitability, cashier/branch performance, sales-by-period,
  tax summary, expense breakdown — all exportable (PDF via existing `printing`,
  CSV). Reuse `reports.*` permissions; add `reports.export` enforcement.
- **M6.2 Tax engine** — formalize tax beyond the per-transaction `tax_amount`:
  configurable tax rates/groups per product/category, inclusive/exclusive,
  multi-rate. (75 files already touch `tax` — consolidate into a real config.)
- **M6.3 Accounting export** — QuickBooks/Xero/CSV journal export (sales,
  refunds, expenses, COGS from M4.3). Read-only export; no external write in v1.
- **M6.4 Budgets** — per-category/branch expense budgets with actual-vs-budget
  tracking; over-budget surfaces on the dashboard + optionally a fraud rule.
- **Permissions:** extend `reports.*`, add `accounting.export`, `budgets.manage`.

**Exit criteria:** owner can answer "am I profitable, what do I owe in tax, am I
on budget" and hand clean numbers to an accountant.

---

# Milestone M7 — Platform & monetization

**Goal:** turn the app into a sellable SaaS platform.

- **M7.1 Subscription / billing & plan enforcement** — the gap `CLAUDE.md`
  already names (no real subscription exists today). **Full spec:
  `docs/UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md`.** Summary:
  - **The cloud is the paywall (v2 model):** **Free = a fully-functional local
    POS on one device — unlimited records, ~₱0 cost to us.** The first thing you
    ever pay for is cloud sync + automatic backup + multi-device. We meter
    cloud/structural dimensions (branches, seats, devices) + advanced modules —
    never receipts, and never local record counts. The POS never stops selling;
    downgrade freezes/reverts, never deletes.
  - **Plans (PHP, PH micro-SMB):** **Free ₱0** (local-only, 1 device, unlimited
    records) → **Starter ₱199/mo** (cloud sync + backup + 2 devices — the cheap
    ~₱6.50/day entry that converts the micro segment) → **Growth ₱499/mo** →
    **Business ₱1,299/mo** → Enterprise (custom). **Launch = Free + Starter**,
    both fully backed by shipped features today.
  - **Pricing is derived, not guessed:** Free is COGS-free (local-only), Starter
    clears cloud COGS with margin; ladder ~2.5–2.6×; the ₱199 rung bridges the
    too-big ₱0→₱499 gap. Validate the anchor against measured COGS before launch.
  - **Yearly discount = "2 months free" (16.667%), calculated not invented:**
    `annual = monthly × 10`, one `discount_months_free = 2` constant (Starter
    ₱1,990/yr, Growth ₱4,990/yr, Business ₱12,990/yr). Verifiable by the customer.
  - **Enforcement is simple now:** because Free never syncs (1 device) and
    products are uncapped on every tier, the v1 multi-device product-overshoot
    problem **dissolves**. Free has nothing to enforce server-side; paid tiers
    meter only low-volume **branches/seats/devices** — device registration is
    online-only, branch/seat counts are enforced by RLS `count < limit`. The
    heavy product `over_limit`/reconcile machinery is dropped.
  - **Enforcement = a third gate layer:** `plan_entitlement ∩ business_module ∩
    permission`, wrapping the existing two-layer system. Limits enforced
    server-side in RLS (branch/seat counts, premium writes) against the
    authoritative `subscriptions` row; cached `entitlement_cache` (Drift,
    read-only) drives offline UX with a sync-timestamp-based grace window
    (clock-tamper resistant).
  - New Supabase `plans` / `plan_limits` / `subscriptions` /
    `subscription_events` (hash-chained, reusing the shipped M1 chain) —
    client-read-only, writes are billing-webhook/service-role only. Permission
    `billing.manage`; owner-only.
- **M7.2 Multi-currency** — currency per business/branch; display + reporting.
- **M7.3 Hardware & integrations** — deepen receipt/label printing
  (`print_bluetooth_thermal` exists), barcode scanning, payment-terminal hooks.
- **M7.4 Notifications/push** — turn the notifications feature into real
  push/digest delivery for fraud flags.

**Exit criteria:** UPSENSO can be sold on tiered plans, enforced securely, with
the hardware/integrations a real shop needs.

---

# Milestone M8 — Hardening, scale & polish (continuous)

Runs alongside every milestone, formalized at the end:

- **M8.1 Delta-sync at scale** — validate `docs/delta_sync_design.md` under large
  datasets; conflict review UI for the `sync_conflicts` cases.
- **M8.2 Security review** — RLS coverage audit across all new tables; keystore
  rotation runbook already exists (`docs/SECURITY_keystore_rotation_runbook.md`).
- **M8.3 Test coverage gates** — enforce the `CLAUDE.md` must-cover areas
  (POS, inventory, permissions, sync, subscription, migrations) in CI.
- **M8.4 Performance** — DB indices for the new analytics/fraud queries; tighten
  `BlocBuilder` selectors; large-catalog POS perf.
- **M8.5 Web parity** — graceful degradation where on-device LLM is unavailable
  (already the pattern); ensure every milestone's web build is clean.

---

## Dependency graph (build order)

```
M3 Inventory depth ──> M4 Procurement intelligence ──> M6.3 COGS/accounting
                                                              │
M5.3 Loyalty ──────────────> M6 Money (reports/tax/budgets) ─┴─> M7 Platform/billing
                                                                       │
M8 Hardening ── continuous across all ─────────────────────────────────┘
```

**Recommended sequence:** M3 → M4 → M6 → M7, with M5.3 (loyalty) insertable when
go-to-market needs it and M8 continuous. The two launch gates — **M-BIR**
(invoice compliance) and **M-LEGAL** (Privacy, Terms, Data Privacy Act) — gate
any commercial release and are tracked in `docs/UPSENSO_EXECUTION_SEQUENCE.md`.

---

## Per-feature definition of done (applies to every item)

A feature ships only when **all** are true (from `CLAUDE.md`):

1. PermissionKeys → AppPermission → AppFeature → role matrix → default matrix
   (run `dart run tool/diff_matrices.dart`, must be in sync).
2. Module gate set (existing or new module + settings toggle).
3. Permission checks in Bloc/UseCase **and** GoRouter guards — never UI-only.
4. Server-side RLS enforces every write (UI restrictions are UX, not security).
5. Offline-first: local Drift write → background sync; `sync_status` lifecycle;
   LWW conflict handling; soft deletes.
6. Drift schemaVersion bumped + `onUpgrade` step + Supabase migration with a
   rollback section (additive, non-destructive).
7. Every `catch (e, st)` logs with stack trace + graceful UI (lottie for network).
8. Reuses `lib/core/widgets/`; no hardcoded colors/styles/spacing.
9. Tests for critical paths (repos mock local+remote, permission resolution,
   sync transitions, error states).
10. AI compatibility: data is queryable by `AiToolService`, branch-filtered and
    permission-scoped.

---

## "Vision complete" — what done looks like

A small/medium business owner installs UPSENSO and can, **fully offline**, run
their entire operation across branches — sell, restock, transfer, purchase, pay
expenses, manage staff and customers — while the app:

- **protects** every record with a tamper-evident audit chain and catches abuse
  with real-time fraud detection *(shipped — M1)*,
- lets them **ask** the on-device AI assistant about their business in plain
  language,
- **forecasts** demand and drafts the purchase orders to prevent stockouts,
- **closes the books** with P&L, tax and accounting exports,
- and is **sold as a tiered SaaS** with secure, offline-tolerant plan
  enforcement.

That is the all-in-one smart business platform. This roadmap is the path to it.
</content>
</invoke>
