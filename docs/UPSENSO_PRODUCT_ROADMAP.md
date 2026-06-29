# UPSENSO — Product Roadmap to "All-in-One Smart Business Platform"

> Status: **proposed master plan** · Branch: `claude/platform-features-roadmap-7bqdgn`
> The single sequenced plan from today's codebase to the full product vision:
> one platform where an SMB runs their whole business — POS, inventory,
> procurement, expenses, people, customers, money — with **offline-first**
> operation and **AI insights + fraud detection** woven through it.

## How to read this

- Work is grouped into **Milestones (M1–M8)**. Each milestone is independently
  shippable and ordered by dependency + value.
- Every feature carries its **mandatory wiring** per `CLAUDE.md`:
  PermissionKeys → AppPermission → AppFeature → both matrices → module gate →
  PermissionService/guards → offline/sync → tests.
- Detailed specs that already exist are referenced, not repeated:
  - `docs/UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` (fraud + audit chain)
- ✅ done · ⚠️ partial · ❌ missing — current state as of this plan.

---

## Where we are today (baseline)

**Built & real:** POS/checkout, sales/refunds (with approval), products/variants/
categories, inventory + stock ledger, recipes/ingredients, procurement
(PO → receipt), expenses (with approval), employees + per-employee permission
overrides, role-specific dashboards, audit log (append-only, RLS-enforced),
on-device AI assistant (NL query + transaction creation), settings/onboarding/
notifications/drafts. RBAC + module gate is mature (68 permissions, server-side
RLS enforcement).

**Promised but not real:**
- ❌ Fraud detection — mocked (`alert` feature uses `mockFraudAlerts`).
- ⚠️ Tamper-evident audit chain — documented, no hash columns in code.
- ⚠️ AI is reactive only — no proactive insights/forecasting.
- ⚠️ Reports — a single page.
- ❌ Stock transfers between branches — permissions + audit action exist; **no
  table, no feature**.
- ❌ Customers / CRM / loyalty — only a `customerName` text field on a sale.
- ❌ Subscription/billing — `CLAUDE.md` names it as must-test; the only
  "subscription" in code is Dart `StreamSubscription`. Nothing exists.
- ❌ Accounting/tax export, budgets/forecasting.

The roadmap below closes every one of these, in order.

---

# Milestone M1 — Trust & Integrity (the core promise)

**Goal:** make "fraud detection" and "tamper-evident audit" real. This is the
highest-leverage work — it's advertised, differentiating, and unblocks AI risk
insights.

Full spec: **`docs/UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md`**. Summary:

- **M1.1 Tamper-evident audit chain** — per-(business, device) SHA-256 hash chain
  on `audit_logs` (+3 nullable cols, Drift v51→v52 + Supabase), shared canonical
  serializer, `AuditChainVerifier`, "Verify integrity" action.
- **M1.2 Fraud detection engine** — real `fraud_flags` table + DAO, deterministic
  rule engine (excessive refunds, high discount, sale-after-shift, inventory
  shrinkage, repeated voids, negative margin, after-hours login, `AUDIT_TAMPER`),
  event-driven + periodic offline sweeps, real data into the existing `alert` UI.
- **Permissions:** `fraud.view`, `fraud.resolve`, `audit_logs.verify`, `nav.fraud`
  under the existing `audit` module.

**Decision recorded:** no public blockchain (offline-first + cost + wrong threat
model). Optional daily head-hash anchoring is the only place any anchoring tech
appears, and it's deferred to M1 Phase 3.

**Exit criteria:** a tampered audit row is detected; refund/void/discount abuse
raises real flags; managers can triage them; all covered by tests.

---

# Milestone M2 — AI from reactive to proactive (the differentiator)

**Goal:** flip the on-device AI from "answer when asked" to "tell me what
matters." Reuses the existing 7-layer pipeline and `AiToolService` query pattern.

- **M2.1 AI Insights digest** — a scheduled, offline-first generator that
  produces a daily/weekly digest card on the dashboard: sales trend vs prior
  period, top/bottom products, margin movers, expense spikes, **open fraud flags
  summary** (reads M1), low-stock/stockout risk (reads M3). Deterministic
  analytics compute the numbers; the LLM only phrases them. Falls back to
  template phrasing when no model is downloaded (web has no LLM).
  - New `AiToolService` methods: `getSalesTrend`, `getTopProducts`,
    `getMarginMovers`, `getExpenseAnomalies`, `getFraudSummary` (all
    branch-filtered + permission-aware like existing queries).
  - New `insights` feature folder (cubit + dashboard card), permission
    `insights.view`, module-gated under `reports`.
- **M2.2 AI NL coverage expansion** — extend tool service to answer the new
  domains (customers, transfers, budgets) as those milestones land.
- **M2.3 Anomaly explanations** — when a fraud flag opens, an "Explain" action
  asks the LLM to narrate the evidence in plain language (read-only; never
  resolves).

**Offline:** all metrics computed from local Drift; LLM optional. **AI never
writes business data** — it reads and phrases.

**Exit criteria:** owner opens the app and sees a plain-language "here's what
changed and what needs attention" card, generated on-device, permission-scoped.

---

# Milestone M3 — Inventory depth (multi-branch operations)

**Goal:** finish inventory as a real multi-branch system.

- **M3.1 Stock transfers between branches** — close the existing stub
  (`transferStockBetweenBranches` / `approveStockTransfer` permissions + audit
  action already exist; no table/feature). New `stock_transfers` +
  `stock_transfer_items` tables (Drift + Supabase), each leg writing the
  `stock_ledger` (`sourceType='transfer'`) on send and receive. Receiving leg
  reconciliation feeds the `transferMismatch` fraud rule (M1).
- **M3.2 Reorder points & low-stock automation** — per-variant/branch reorder
  level + safety stock; surfaces low-stock on dashboard and feeds M2 insights.
- **M3.3 Demand forecasting (lightweight)** — moving-average / seasonal-naive
  projection from `stock_ledger` sales history → "days of cover" + suggested
  reorder qty. Deterministic, on-device. Feeds M2 + M4 auto-PO suggestions.
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
  from `purchase_orders` + `goods_receipts`. Feeds supplier selection + insights.
- **M4.3 Landed cost / cost history** — track unit cost over time from receipts;
  powers the `NEGATIVE_MARGIN_SALE` fraud rule (M1) and margin analytics (M2/M6).
- **Permissions:** reuse `procurement.*`.

**Exit criteria:** the app suggests what to reorder, from whom, at what expected
cost — owner just approves.

---

# Milestone M5 — Customers & CRM (new revenue surface)

**Goal:** turn the anonymous `customerName` field into a real customer entity —
required for "manage your whole business."

- **M5.1 Customer directory** — new `customers` table (Drift + Supabase,
  offline-first, soft-delete), link transactions/refunds to `customer_id`
  (keep `customerName` as fallback for walk-ins). New `customers` feature folder.
- **M5.2 Purchase history & balances** — per-customer transaction history,
  store credit / outstanding balance (ties to refunds as store credit).
- **M5.3 Loyalty (points / tiers)** — configurable points-per-spend, redemption
  at POS. Offline-first accrual; LWW-safe ledger (`loyalty_ledger`).
- **New module:** `customers` in `business_modules` + settings toggle.
- **Permissions:** `customers.view/create/edit/delete`, `loyalty.manage`,
  `nav.customers`; AppFeature `customerDirectory`; both matrices; RLS.

**Exit criteria:** owner knows who their customers are, what they bought, and can
reward repeat business — all offline-capable.

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
  tracking; over-budget feeds M2 insights + optionally a fraud rule.
- **Permissions:** extend `reports.*`, add `accounting.export`, `budgets.manage`.

**Exit criteria:** owner can answer "am I profitable, what do I owe in tax, am I
on budget" and hand clean numbers to an accountant.

---

# Milestone M7 — Platform & monetization

**Goal:** turn the app into a sellable SaaS platform.

- **M7.1 Subscription / billing & plan enforcement** — the gap `CLAUDE.md`
  already names (no real subscription exists today). **Full spec:
  `docs/UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md`.** Summary:
  - **Fair-to-customer, offline-first by design:** the POS never stops selling,
    you always own/export your data, limits are on *value* dimensions
    (branches, seats, advanced modules) — never on number of receipts — and a
    generous offline grace window means a lapsed/offline device degrades premium
    features to read-only rather than locking the owner out.
  - **Plans (PHP, PH market):** Free (1 branch / 2 seats / 2 devices / 100
    products) → Growth (₱499/mo) → Business (₱1,299/mo) → Enterprise (custom),
    each unlocking modules/AI/fraud/CRM/accounting by tier.
  - **Pricing is derived, not guessed:** tiers ladder ~2.6×, seat add-ons priced
    below blended rate (₱99→₱79), with a COGS floor to validate before launch.
  - **Yearly discount = "2 months free" (16.667%), calculated not invented:**
    `annual = monthly × 10`, driven by a single `discount_months_free = 2`
    constant so prices can't drift (Growth ₱4,990/yr saves ₱998; Business
    ₱12,990/yr saves ₱2,598). Customers can verify the saving themselves.
  - **Offline-first limit enforcement (the multi-device problem):** a hard global
    cap is impossible without write-time coordination, so we use **optimistic
    edge soft-checks + authoritative server reconciliation that never deletes
    data**. If offline devices collectively overshoot a limit (e.g. 100-product
    Free cap), all rows persist and stay sellable; the account enters an
    `over_limit` state that soft-locks only *new* creates until upgrade or
    archive. Abuse is bounded by an online-only **device cap** and a server-side
    `COUNT(*)` a tampered client can't shrink — so the exploit yields nothing
    durable. Optional quota-leasing documented for true hard caps.
  - **Enforcement = a third gate layer:** `plan_entitlement ∩ business_module ∩
    permission`, wrapping the existing two-layer system. Limits enforced
    server-side in RLS (branch/seat counts, premium writes) against the
    authoritative `subscriptions` row; cached `entitlement_cache` (Drift,
    read-only) drives offline UX with a sync-timestamp-based grace window
    (clock-tamper resistant).
  - New Supabase `plans` / `plan_limits` / `subscriptions` /
    `subscription_events` (hash-chained, reusing M1) — client-read-only, writes
    are billing-webhook/service-role only. Permission `billing.manage`;
    owner-only.
- **M7.2 Multi-currency** — currency per business/branch; display + reporting.
- **M7.3 Hardware & integrations** — deepen receipt/label printing
  (`print_bluetooth_thermal` exists), barcode scanning, payment-terminal hooks.
- **M7.4 Notifications/push** — turn the notifications feature into real
  push/digest delivery for fraud flags + insights.

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
M1 Trust ──┬─> M2 AI Insights ──> (consumes all later data)
           │
M3 Inventory depth ──> M4 Procurement intelligence
           │                     │
           └────────────┐        └─> M6.3 COGS/accounting
                        ▼
M5 Customers/CRM ──> M6 Money (reports/tax/budgets) ──> M7 Platform/billing
                                                            │
M8 Hardening ── continuous across all ──────────────────────┘
```

**Recommended sequence:** M1 → M2 → M3 → M4 → M5 → M6 → M7, with M8 continuous.
M1 first (it's the promise + unblocks AI risk insights). M2 early so every later
milestone immediately gains an insight surface. M5 (customers) can move earlier
if go-to-market needs loyalty sooner — it has no hard dependency on M3/M4.

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
  with real-time fraud detection,
- **advises** them daily in plain language (on-device AI) on sales, stock,
  margin, cash and risk,
- **forecasts** demand and drafts the purchase orders to prevent stockouts,
- **closes the books** with P&L, tax and accounting exports,
- and is **sold as a tiered SaaS** with secure, offline-tolerant plan
  enforcement.

That is the all-in-one smart business platform. This roadmap is the path to it.
