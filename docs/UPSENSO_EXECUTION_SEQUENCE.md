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

Spec: `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` Part 1. Self-contained, ships alone.

1. [ ] **Canonical serializer** — `lib/core/audit/audit_hash.dart`:
       `canonicalAuditPayload(...)` (sorted keys, UTC ISO-8601 ms, no sync
       fields) + `sha256` helper. *Pure, unit-testable first.*
   - [ ] Tests: stable output, metadata key-order independence, UTC formatting.
2. [ ] **Drift schema** — add `seq`, `prevHash`, `entryHash` (nullable) to
       `audit_logs_table.dart`; bump `schemaVersion` 51→52 in `app_database.dart`
       + `onUpgrade` (3× `ADD COLUMN`).
3. [ ] **Codegen** — `dart run build_runner build --delete-conflicting-outputs`.
4. [ ] **Supabase migration** — `<ts>_audit_chain_columns.sql` (additive, with
       rollback comment). Apply (ask before running the CLI/MCP write).
5. [ ] **Write path** — update `AuditLogService.log()` to allocate `seq` +
       compute the chain hash inside one Drift transaction (per-business/device).
   - [ ] Tests: seq increments per (business, device); genesis; concurrent writes.
6. [ ] **Verifier** — `lib/core/audit/audit_chain_verifier.dart` (re-walk +
       detect breaks).
   - [ ] Tests: clean chain passes; one mutated row → one break at right seq.
7. [ ] **UI hook** — "Verify integrity" action on the Audit Logs page, gated by
       `audit_logs.verify` (add the permission key + matrices first).

**CHECKPOINT:** new audit rows carry a valid chain; tampering with a row is
detected by the verifier; `flutter test` + `dart run tool/diff_matrices.dart` green.

---

## Phase 2 — M1.2 Fraud Detection Engine  *(~1.5 weeks)*

Spec: `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` Part 2. Replaces the mock `alert`.

8.  [ ] **Permissions wiring (do first, per CLAUDE.md order):** add `fraud.view`,
        `fraud.resolve`, `nav.fraud`, `audit_logs.verify` to `permission_keys.dart`
        → `AppPermission` values → `AppFeature.fraudAlerts` (module `audit`) →
        `role_permission_matrix.dart` + `default_permission_matrix.dart`.
    - [ ] `dart run tool/diff_matrices.dart` must report in-sync.
9.  [ ] **Drift table** — `fraud_flags_table.dart` + `fraud_flags_dao.dart`
        (+ unique index on `business_id, dedupe_key`); bump schemaVersion + upgrade;
        `build_runner`.
10. [ ] **Supabase migration** — `<ts>_fraud_flags.sql` mirror + RLS
        (`fraud.view` SELECT, `fraud.resolve` UPDATE, INSERT tenant-scoped, no
        DELETE). Rollback section. Apply (ask first).
11. [ ] **Rule framework** — `FraudRule` interface + `FraudScanContext` +
        `fraud_settings` thresholds.
12. [ ] **First 5 rules:** `EXCESSIVE_REFUNDS`, `HIGH_DISCOUNT`,
        `SALE_AFTER_SHIFT`, `INVENTORY_SHRINKAGE`, `AUDIT_TAMPER` (wires Phase 1
        verifier).
    - [ ] Tests per rule: positive, negative, boundary, dedupe.
13. [ ] **Engine** — `fraud_detection_engine.dart`: `runSweep()` + dedupe +
        notification; register in `di.dart`.
14. [ ] **Triggers** — post-commit hooks in `CheckoutService` / `RefundService` /
        `StockMovementService` (incremental) + foreground/periodic full sweep.
15. [ ] **UI swap** — replace `mockFraudAlerts` with a real `FraudCubit` →
        `FraudFlagsDao` stream in the existing `alert` feature; add resolve/dismiss
        (gated by `fraud.resolve`, writes an audit log).

**CHECKPOINT:** real refund/discount/shift/shrinkage abuse raises real flags; a
broken audit chain raises a CRITICAL flag; manager can triage; cashier denied;
all tests green.

> **M1 is now shippable.** This is the realistic 1-month (Max 5×) target. Stop
> here and release if time-boxed; continue if you have runway.

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
17. [ ] **Insights generator** — deterministic metrics compute the numbers; LLM
        only phrases them; template fallback when no model (web).
18. [ ] **Permissions** — `insights.view` (module `reports`); matrices; diff check.
19. [ ] **Dashboard card** — `insights` feature folder + cubit + a reusable
        insight card widget on the role dashboards.

**CHECKPOINT:** owner opens the app and sees a plain-language daily "what changed
+ what needs attention" card, generated on-device, permission-scoped.

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
26. [ ] **M7.1 Subscription & limits** — spec in
        `UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md` (PHP pricing, entitlement
        layer, offline distributed-limit reconciliation). Needs a payment gateway
        (GCash/Maya/card) — its own sub-project.
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

> Live status so any session (or a fresh Claude one — no memory between sessions)
> resumes exactly here. **Last updated: 2026-06-30.**

### Active priority order
**M2 (AI insights) → M5 (CRM) → M1 (fraud+audit, deferred) → M-BIR → M-LEGAL → ship.**
(See the "Priority override" section near the top for the rationale.)

### Done
- ✅ All planning/spec docs (on `main`): `UPSENSO_PRODUCT_ROADMAP.md`,
  this file, `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md`,
  `UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md`, `UPSENSO_BIR_COMPLIANCE.md`.
- ✅ **M2 Task 1 — VERIFIED & ON `main`.** `getSalesTrend`, `previousPeriod`,
  `SalesTrendResult`, `getApprovedExpenseTotal` in
  `lib/features/ai_assistant/services/ai_tool_service.dart`; tests in
  `test/features/ai_assistant/ai_tool_service_analytics_test.dart`.
  `flutter analyze` clean + all 9 tests pass **(run locally 2026-06-30)**.
  The old feature branch was merged into `main` (commit `345e10f`).
- ✅ **M2 Task 16 analytics methods — `getTopProducts`, `getLowStockCount`,
  `getMarginMovers`** (+ `MarginMoverResult`). Added to `ai_tool_service.dart`
  2026-06-30. Analyze clean; **13 analytics tests pass.** `getLowStockCount`
  reuses `ProductVariantsDao.getLowStockByBusinessId` (matches the dashboard
  low-stock card); `getMarginMovers` uses current-cost approximation (decision
  logged above). Only `getFraudSummary` remains (deferred with M1).
  **All uncommitted in the working tree** — commit pending user's go-ahead.

### Next action
- ⬜ **Task 17** insights generator → **18** `insights.view` permission (module
  `reports`; both matrices + `dart run tool/diff_matrices.dart`) → **19**
  dashboard card (`insights` feature folder + cubit + reusable insight card).

### Repo/branch state
- **All M2 code is now on `main`** (the old `claude/platform-features-roadmap-7bqdgn`
  branch was merged and no longer exists locally/remotely).
- Latest uncommitted local change: `getTopProducts` + `getLowStockCount` in
  `ai_tool_service.dart` (not yet committed — commit only on user's request).
- PR #11 merged (docs). Working rule: **never `git push` / commit without an
  explicit green light** from the user.

### Environment note for future sessions
- This local Windows session **DOES** have the Flutter SDK
  (`/c/Softwares/flutter/bin/flutter`) → you CAN run `flutter analyze` /
  `flutter test` / `build_runner` here. (Earlier remote sessions could not — if
  a future session is remote with no SDK, fall back to write+self-review and say
  so honestly; never claim tests passed when they weren't run.)
