# UPSENSO — Production-Hardening Roadmap

Execution plan derived from `findings.md`. Finding IDs (PR-xx, RL-xx, …) link back to the evidence there.

Effort key: S ≤1 day · M 2–5 days · L 1–3 weeks · XL >3 weeks.
Phases are ordered; tasks inside a phase can run in parallel unless a dependency says otherwise.
This roadmap is designed to interleave with the product roadmap (`UPSENSO_PRODUCT_ROADMAP.md`): Phase 1 blocks everything; Phases 2–3 should land **before** M1 (fraud/audit) because M1 consumes ledger/audit data these phases make trustworthy.

---

## Phase 1 — Critical Foundations (week 1; do not ship features past this until done)

### 1.1 CI quality gate before deploy — `PR-01`
- **Priority:** P0 · **Effort:** S · **Dependencies:** none
- **Steps:**
  1. Add `.github/workflows/checks.yml` triggered on `pull_request` and `push` to `main`: `flutter pub get` → `flutter analyze --fatal-infos` → `flutter test` → `dart run tool/diff_matrices.dart`.
  2. In `deploy.yml`, add `needs: checks` (move checks into the same workflow or use `workflow_run`).
  3. Add a guard step failing CI when files under `lib/core/database/tables/` change without a `schemaVersion` diff in `app_database.dart`.
- **Success criteria:** A PR with a failing test cannot merge green; `main` cannot deploy without analyze+test passing.

### 1.2 Staged Play Store rollout — `PR-01`
- **Priority:** P0 · **Effort:** S · **Dependencies:** 1.1
- **Steps:** Change `upload-google-play` to `tracks: internal` (promote manually), or keep `production` with `status: inProgress` + `userFraction: 0.1`; document the promotion procedure in `docs/`.
- **Success criteria:** A bad build can be halted before full fleet exposure.

### 1.3 Crash reporting + structured logger — `RL-03`, `PR-02`
- **Priority:** P0 · **Effort:** M · **Dependencies:** none
- **Steps:**
  1. Add `sentry_flutter`; init in `main.dart` inside the existing error-handler setup, keyed by `AppEnv` flavor (no-op in dev).
  2. Create `lib/core/logging/app_logger.dart` — `AppLogger.error(feature, method, e, st)` preserving the `[Feature] Error in methodName: $e\n$st` format; warn/error levels forward to Sentry with breadcrumbs.
  3. Mechanical sweep: replace `debugPrint` in `catch (e, st)` blocks (282 sites; prioritize `core/` and sync) with the logger; leave pure-debug traces as `AppLogger.debug`.
  4. Upload obfuscation symbols in CI (`sentry-cli` step after build) — `PR-05`.
  5. Emit one breadcrumb per `SyncResult` (entity counts, failure counts).
- **Success criteria:** A forced test crash and a forced sync failure both appear in Sentry with readable stacks and feature tags, from a release build.

### 1.4 Fix offline-startup local sign-out — `RL-01`
- **Priority:** P0 · **Effort:** S–M · **Dependencies:** none
- **Steps:**
  1. In `bootstrap.dart` `_waitForSessionRecovery`, catch `AuthException` separately; call `signOut(scope: local)` **only** for token-invalid codes (`refresh_token_not_found`, `invalid_grant`); on any other error keep the session and continue to the cached-context path.
  2. Add a retry-on-connectivity hook: when `ConnectivityService` reports online and the session is unverified, run `refreshSession()` once.
  3. Unit-test with a faked `GoTrueClient` (offline exception vs. revoked-token exception).
- **Success criteria:** Airplane-mode cold start with an expired access token lands on the dashboard with cached data, and re-validates when connectivity returns.

### 1.5 Harden inventory branch guard — `RL-02`
- **Priority:** P0 · **Effort:** S · **Dependencies:** none
- **Steps:** Replace `assert(false); return;` with `throw ArgumentError` in `inventory_repository.dart` (`recordSaleDeductions`, `reverseSaleDeductions`); make `branchId` non-nullable in `IInventoryRepository`, `CheckoutService.completeSale`, `RefundService` internals; resolve the null fallback at the two checkout pages / refund sheet before the call.
- **Success criteria:** Compiling code cannot record a sale without a branch; a regression test proves a null-branch attempt aborts the whole sale transaction.

### 1.6 First money-path tests (safety net for later phases) — `CQ-01`
- **Priority:** P0 · **Effort:** M · **Dependencies:** none (needed *before* Phase 3/4 refactors)
- **Steps:**
  1. Add in-memory Drift harness (`AppDatabase.forTesting(NativeDatabase.memory())`).
  2. `CheckoutService`: sale commits transaction+items+ledger+level atomically; oversell throws `InsufficientStockException` and leaves zero rows; invoice number persisted.
  3. `RefundService`: over-refund rejected; restock pins to the sale's branch; partial → `partially_refunded`.
  4. `StockMovementService`: ledger `quantity_before/after` matches level changes; variant total = Σ branch levels.
- **Success criteria:** `flutter test test/core/services/` green in CI; mutation of any money-path file without tests is a review flag.

---

## Phase 2 — Reliability Improvements (weeks 2–3)

### 2.1 Universal push backoff — `RL-04`
- **Priority:** P1 · **Effort:** S · **Dependencies:** none
- **Steps:** Apply `_shouldSkipForBackoff` in every `_syncX` loop (all entities have `lastSyncAttempt`/`sync_error` columns or can skip when absent); log a Sentry breadcrumb when a row exceeds N consecutive failures.
- **Success criteria:** A poison row generates ≤1 request per 5-minute window; surfaced in telemetry after 5 failures.

### 2.2 Fold audit/receipt sync into result aggregation — `RL-05`
- **Priority:** P1 · **Effort:** S · **Dependencies:** none
- **Steps:** `_syncAuditLogs`/`_syncReceiptSettings` return `SyncResult`; include in totals/errors; delete the special-cased 42501 duplicate.
- **Success criteria:** UI pending/sync state reflects audit-log failures; single tenant-rejection code path.

### 2.3 Migration integrity: checked steps + schema validation + tests — `RL-08`
- **Priority:** P1 · **Effort:** M–L · **Dependencies:** 1.3 (telemetry)
- **Steps:**
  1. Replace blind `try/catch` ALTERs in `app_database.dart` with `pragma_table_info` existence checks (v44 pattern) — behavior-preserving.
  2. Run drift's `validateDatabaseSchema()` after upgrade in debug; report mismatches to Sentry in release.
  3. Adopt drift_dev schema snapshots + step-by-step migration tests; generate snapshots for v45→v51 now, and for every future version.
  4. Snapshot the SQLite file before any table-rewriting upgrade; delete on success (`PR-03`).
- **Success criteria:** CI proves a v45 fixture DB upgrades to v51 with identical logical schema to a fresh install; drift telemetry shows zero schema-mismatch reports after rollout.

### 2.4 Web bootstrap hard-failure screen — `RL-06`
- **Priority:** P2 · **Effort:** S · **Dependencies:** none
- **Steps:** Distinguish timeout (retry w/ splash) from hard failure (full-screen Lottie error + retry button re-running `ensureReady`).
- **Success criteria:** Web session with broken storage shows one clear error screen, not per-feature failures.

### 2.5 Fleet visibility heartbeat — `PR-02`
- **Priority:** P1 · **Effort:** M · **Dependencies:** 1.3
- **Steps:** Daily upsert per device into a `device_health` table (app version, schema version, pending-sync count, last successful sync, platform); Supabase scheduled query alerting on stuck devices (pending > 0 for > 24 h).
- **Success criteria:** A dashboard/query answers "which devices haven't fully synced in 24 h" without touching a device.

---

## Phase 3 — Data Integrity Enhancements (weeks 3–5)

### 3.1 Immutable invoice numbers — `DI-02`
- **Priority:** P1 · **Effort:** M · **Dependencies:** decision from product owner (BIR direction, see §9 of `UPSENSO_BIR_COMPLIANCE.md`)
- **Steps:**
  1. Decide the scheme: per-device series (`INV-{deviceCode}-NNNNNN`) recommended — offline-safe, BIR-compatible, no reassignment ever.
  2. Add device code to claim paths (`invoice_number_service.dart`); make the server unique index `(business_id, invoice_number)` naturally collision-free across devices.
  3. Delete the reclaim-on-23505 path in `_syncTransactions`; a 23505 becomes a hard telemetry alert (it now indicates a real bug).
  4. Backfill note: existing numbers stay; new scheme applies forward.
- **Success criteria:** Two devices selling offline all day sync with zero collisions; printed receipt == stored invoice number, always.

### 3.2 Align local/server stock semantics — `DI-03`
- **Priority:** P2 · **Effort:** M · **Dependencies:** 1.6 (tests)
- **Steps:** Remove the `clamp(0.0, …)` in `InventoryLevelsDao.adjustQuantity` and `StockMovementService`; UI badges negative stock as "oversold"; add a weekly server reconciliation (level vs. Σ ledger) function reporting drift to telemetry.
- **Success criteria:** Simulated two-device oversell converges to the same (negative) number on both devices and the server; reconciliation reports zero unexplained drift.

### 3.3 LWW + conflict logging for all mutable entities — `DI-04`
- **Priority:** P2 · **Effort:** M · **Dependencies:** none (easier after 4.1)
- **Steps:**
  1. Audit every `upsertFromServer` for a pending-changes guard; add where missing (uniform rule: never overwrite `sync_status != synced`).
  2. Extend `client_updated_at` conditional updates + `_logSupersededConflict` to expenses, suppliers, POs (products/variants pattern).
  3. Convert expense/PO **status transitions** to server RPCs with precondition checks (approve requires `status = pending`), replacing blind status upserts.
- **Success criteria:** Two-device offline edit race on a supplier logs a conflict and converges; an offline double-approval race cannot produce approved-by-two or approved-after-rejected.

### 3.4 Complete the logout wipe + pending-count sets — `DI-05`
- **Priority:** P1 (GR pending-count hole) / P2 (rest) · **Effort:** S · **Dependencies:** none
- **Steps:** Add goods receipts/items to `pendingSyncCount`; add `employee_permissions`, `business_modules`, `procurement_settings`, `refund_settings`, sequence tables to `clearLocalData`; test that wipe-refusal covers every pushed entity.
- **Success criteria:** Logout with any pending entity refuses; post-logout DB contains zero tenant rows.

### 3.5 Money as integer minor units — `DI-01`
- **Priority:** P1 decision now, P2 execution · **Effort:** XL (phased) · **Dependencies:** 1.6, 2.3 (migration testing)
- **Steps:**
  1. Introduce `Money` value type (int centavos, currency-aware formatting via existing formatters).
  2. New tables/features use int columns from day one (CRM, subscriptions).
  3. Migrate `transactions`/`transaction_items`/`refunds`: Drift v52 rewrite (REAL×100 → INTEGER with rounding), Supabase migration casting `numeric` columns, dual-read shim during rollout.
  4. Replace `1e-6` epsilon comparisons with exact int math; largest-remainder allocation for tax/discount line splits.
- **Success criteria:** Σ line totals == header total, exactly, for every historical and new sale; property test over random carts proves allocation invariants.

### 3.6 Audit-log durability (pre-M1) — `DI-07`
- **Priority:** P2 · **Effort:** M · **Dependencies:** M1 design doc (exists)
- **Steps:** Opportunistic immediate push of audit rows when online (don't wait for the 60 s cycle); device-sequence numbering now (cheap, enables gap detection later); hash chain lands with M1.
- **Success criteria:** Online devices have < 5 s audit-log ingestion latency; server can detect a device-sequence gap.

---

## Phase 4 — Architecture Refinement (weeks 5–8, interleaved with feature work)

### 4.1 Sync engine registry refactor — `AR-01`, `CQ-02`, `PE-04`
- **Priority:** P1 · **Effort:** L · **Dependencies:** 1.6 + characterization tests (write per-entity golden tests as each entity migrates)
- **Steps:**
  1. Define `EntitySyncer` (`pushPending`, `pull(cursor)`, `pendingCount`, `watchPendingCount`, `clearLocal`, `displayName`).
  2. Extract the generic push loop (status switch + backoff + error recording) into a base class; FK-recovery and invoice-reclaim become overridable hooks on the specific syncers.
  3. Migrate one entity per PR (start with suppliers — simplest; end with transactions — most special-cased).
  4. `SyncService` shrinks to engine + registry + tenant guards; `pendingSyncCount`/`watch`/`clearLocalData` iterate the registry (kills DI-05's class of bug structurally).
- **Success criteria:** Adding a synced entity = 1 syncer class + 1 registry line; `sync_service.dart` < 400 lines; all Phase-2/3 sync tests still green.

### 4.2 Checkout/refund orchestration into Bloc/UseCase — `AR-03`
- **Priority:** P1 · **Effort:** M · **Dependencies:** 1.5, 1.6
- **Steps:** One `CompleteSaleUseCase` + `CheckoutBloc` consumed by both `product_checkout_page.dart` and `checkout_payment_page.dart`; refund submission likewise. Widgets emit events and render states only.
- **Success criteria:** Zero `sl<CheckoutService>()` in widget files; bloc_test covers success/oversell/offline paths once, for both screens.

### 4.3 Widget monolith decomposition — `AR-02`, `PE-05`
- **Priority:** P1 · **Effort:** L (one file per PR) · **Dependencies:** none
- **Order:** `receipt_settings_section.dart` (worst) → `main_navigation_page.dart` → `employee_permissions_page.dart` → `po_form_page.dart` → `pos_terminal_page.dart`.
- **Steps per file:** Extract private widget classes to `presentation/widgets/`; convert page-level `setState` clusters to a Cubit; scope `BlocBuilder`s with `buildWhen`; add `const` constructors.
- **Success criteria:** No file in `lib/features/` over ~600 lines; DevTools rebuild counts on the POS screen drop measurably during typing.

### 4.4 Router/DI injection cleanup — `AR-04`, `AR-05`
- **Priority:** P2 · **Effort:** M · **Dependencies:** 4.2 helps
- **Steps:** `buildRouter(...)` factory taking dependencies; per-feature `registerXModule(GetIt)` split of `di.dart`; widgets receive dependencies via `BlocProvider`/constructors.
- **Success criteria:** Router guard unit tests run with fakes; `di.dart` < 100 lines of composition.

### 4.5 Reports repository decomposition + SQL aggregation — `AR-06`, `PE-03`
- **Priority:** P2 · **Effort:** M · **Dependencies:** none
- **Steps:** Split `reports_repository.dart` by domain; convert in-memory folds to SQL aggregates; paginate raw lists; verify local indices for `(business_id, created_at)` query shapes.
- **Success criteria:** Reports over a 50k-transaction fixture DB render without loading >1k rows into memory.

---

## Phase 5 — Performance Optimization (weeks 8–10)

### 5.1 Delta pull for every entity — `PE-01`
- **Priority:** P1 (highest-leverage scale fix) · **Effort:** M · **Dependencies:** 4.1 (much easier after; can start before)
- **Steps:** Extend `_pullIncremental` (or the registry's `pull`) to categories, expenses, branches, employees, suppliers, POs, PO lines, goods receipts, recipe lines; all have `updated_at` server-side; add keyset ordering to each remote-DS query; handle soft-deletes via `deleted_at` in the delta window (already the products pattern).
- **Success criteria:** Steady-state sync cycle for an idle business transfers ~0 rows; Supabase egress per device drops >90% (measure before/after via dashboard).

### 5.2 Batched pushes — `PE-02`
- **Priority:** P2 · **Effort:** M · **Dependencies:** 4.1
- **Steps:** Page pending rows (50–100) into single PostgREST `upsert` calls; one local status update per page; keep entity ordering (parents before children) as today.
- **Success criteria:** 200-sale offline catch-up completes in seconds, ≤10 requests, on a simulated 3G link.

### 5.3 Sync cadence tuning — `PE-01`
- **Priority:** P2 · **Effort:** S · **Dependencies:** 5.1, and push-on-write reliability
- **Steps:** Trigger push immediately on local write (debounced); relax the periodic timer to 5 min ± jitter; keep connectivity-restore trigger.
- **Success criteria:** P95 local-write→server latency ≤ 10 s online; background cycles reduced 5×.

### 5.4 Single-query pending badge — `PE-04`
- Folded into 4.1 (registry exposes one UNION count query). **Success criteria:** one watched query total.

---

## Phase 6 — Production Hardening (weeks 10–12, pre-scale gate)

### 6.1 Local database encryption — `SEC-01`
- **Priority:** P1 · **Effort:** M · **Dependencies:** 2.3 (migration tests, since first launch re-keys the DB)
- **Steps:** Swap `sqlite3_flutter_libs` → `sqlcipher_flutter_libs`; key from `flutter_secure_storage`/Keystore; one-time migrate-and-encrypt existing DBs on upgrade (with the Phase-2 pre-migration snapshot); document web's browser-sandbox model.
- **Success criteria:** Pulling the SQLite file off a device yields ciphertext; upgrade path verified on fixture DBs.

### 6.2 Staging environment + migration workflow — `PR-04`
- **Priority:** P1 · **Effort:** M · **Dependencies:** none
- **Steps:** Staging Supabase project (or preview branches); CI applies migrations to staging and runs a smoke sync (debug build or integration test) before production apply; document the promote procedure.
- **Success criteria:** No migration reaches prod without having run against staging with realistic data.

### 6.3 Tenant data export + backup posture — `PR-03`
- **Priority:** P1 · **Effort:** M · **Dependencies:** none
- **Steps:** Enable/document PITR; per-business CSV export (sales, expenses, inventory, audit) behind `settings.edit_business`; retention statement for the Data Privacy Act work (M-LEGAL).
- **Success criteria:** An owner can self-serve a full export; RPO documented.

### 6.4 Module entitlement server-side (pre-M7) — `SEC-02`
- **Priority:** P2 · **Effort:** M · **Dependencies:** M7 design
- **Steps:** Flip absent-module default to disabled for non-core modules; add server-side entitlement checks (RLS or RPC) keyed to `business_modules`.
- **Success criteria:** A REST call from a business with a disabled module is rejected server-side, not just hidden client-side.

### 6.5 AI tool scoping centralization — `SEC-03`
- **Priority:** P2 · **Effort:** S–M · **Dependencies:** none (do before M2 expands tools)
- **Steps:** Inject `PermissionService`/`DataScopingLayer` into `AiToolService`; resolve scope inside the service; forbid clause-fragment interpolation by convention + a targeted lint/review rule.
- **Success criteria:** A cashier-scoped session cannot obtain all-branch aggregates via the assistant, verified by test.

### 6.6 Release/runbook completion — `PR-05`
- **Priority:** P2 · **Effort:** S · **Dependencies:** 1.3
- **Steps:** Git tags per release; CHANGELOG; symbol upload (done in 1.3); on-call/support runbook (how to read Sentry, how to unstick a device's failed rows, how to run the reconciliation report).
- **Success criteria:** A new engineer can triage a production incident from the runbook alone.

---

## Sequencing summary

```
Week 1        Phase 1 (all six tasks — small, independent)
Weeks 2–3     Phase 2 + start 3.1/3.4
Weeks 3–5     Phase 3 (3.5 money migration is a background track)
Weeks 5–8     Phase 4 (4.1 registry is the centerpiece; 4.3 in parallel)
Weeks 8–10    Phase 5 (5.1 delta-everything is the scale gate)
Weeks 10–12   Phase 6 (encryption, staging, export) → ready for M1/BIR push
```

The single most important dependency edge: **tests (1.6) before refactors (4.x) before scale work (5.x)** — do not reorder it.
