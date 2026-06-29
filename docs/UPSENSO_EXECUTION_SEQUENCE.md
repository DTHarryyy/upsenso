# UPSENSO — Execution Sequence (what to do next, in order)

> Status: **active build sequence** · Branch: `claude/platform-features-roadmap-7bqdgn`
> This is the **ordered task list** from the current codebase to the product
> vision. The *what & why* live in `UPSENSO_PRODUCT_ROADMAP.md`; the *how* for the
> hard parts live in `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` and
> `UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md`. **This doc says what to do first.**

## How to use this

- Work **top to bottom**. Each step is gated on the one before it.
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

16. [ ] **Analytics tool methods** in `ai_tool_service.dart` (branch-filtered,
        permission-aware like existing queries): `getSalesTrend`,
        `getTopProducts`, `getMarginMovers`, `getExpenseAnomalies`,
        `getFraudSummary` (reads Phase 2).
    - [ ] Tests for each query (totals, branch filter, permission scope).
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
25. [ ] **M7.1 Subscription & limits** — spec in
        `UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md` (PHP pricing, entitlement
        layer, offline distributed-limit reconciliation). Needs a payment gateway
        (GCash/Maya/card) — its own sub-project.
26. [ ] **M7.2–7.4** multi-currency, hardware/integrations, push notifications.
27. [ ] **M8** (continuous) — delta-sync at scale + conflict UI, security/RLS
        audit, CI test gates, performance, web parity.

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

## Current position

- ✅ Planning docs complete (roadmap, fraud+audit, subscription/limits, this).
- ⬜ **Next action: Step 0**, then Phase 1 Task 1 (the canonical serializer).
