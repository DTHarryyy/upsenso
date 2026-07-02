# UPSENSO — Production-Readiness Review: Findings

Conventions:
- **Priority:** P0 (fix before next release) · P1 (fix within 1–2 sprints) · P2 (schedule deliberately) · P3 (opportunistic).
- **Effort:** S (≤1 day) · M (2–5 days) · L (1–3 weeks) · XL (>3 weeks).
- File references are `path:line` against the reviewed tree (branch `claude/flutter-pos-readiness-review-kcfhd5`, based on `main` @ `9a25790`).
- Findings that could not be verified at runtime (no Flutter SDK in the review environment) state their assumption explicitly.

---

## 1. Architecture

### AR-01 — `SyncService` is a 2,712-line monolith with 34 constructor dependencies
- **Priority:** P1 · **Effort:** L
- **Description:** `lib/core/sync/sync_service.dart` hand-codes push (`_syncBranches`, `_syncCategories`, `_syncProducts`, … ×17), pull (`pullFromServer`, ~430 lines), pending-count aggregation (`pendingSyncCount`, 15 hand-listed DAOs), a 17-subscription manual stream merge (`watchTotalPendingSyncCount`, lines 326–446), result aggregation repeated three times across ~120 lines (`syncAll` lines 500–622), and logout wiping (`clearLocalData`). Adding one synced entity requires ~8 coordinated edits in this one file plus DI.
- **Current impact:** High change cost and high defect surface — the repair/backfill code visible in the file (`backfillNullBusinessId`, v44-style fixups in `app_database.dart`) shows this area has already produced production bugs. `_syncAuditLogs` returning `void` forced a special-cased duplicate of the 42501 tenant-rejection logic (lines 2146–2185) precisely because it can't participate in the shared result flow.
- **Future risk:** Every roadmap milestone (M1 fraud chain, M5 CRM, M7 subscriptions) adds entities; the file grows superlinearly and merge conflicts/copy-paste drift become the norm. Missed edits fail silently (an entity that never gets counted in `pendingSyncCount` will be wiped by `clearLocalData` despite pending rows).
- **Recommendation:** Introduce an `EntitySyncer` interface (`pushPending()`, `pull(cursor)`, `pendingCount()`, `watchPendingCount()`, `clearLocal()`), one implementation per entity, registered in a list. `SyncService` becomes a ~200-line engine that iterates the registry, aggregates `SyncResult`s, and owns the concurrency/tenant guards (which are good — keep `resolveSyncBusinessId` and `containsTenantRejection` as-is; they're already extracted and pure). Migrate one entity per PR; the existing behavior is characterization-testable per entity.

### AR-02 — Widget-layer files massively exceed the project's own size/responsibility rules
- **Priority:** P1 · **Effort:** L (spread across files)
- **Description:** CLAUDE.md mandates one-responsibility files and ~40-line functions. Actual: `features/settings/presentation/widgets/receipt_settings_section.dart` **2,731 lines / 23 `setState` calls**; `features/employees/presentation/pages/employee_permissions_page.dart` 1,804; `features/procurement/presentation/pages/po_form_page.dart` 1,658; `features/home/presentation/main_navigation_page.dart` 1,625 (nav shell + sidebar + sync-status provider + accordion + 10 private widget classes in one file); `features/pos/presentation/pos_terminal_page.dart` 1,402; `features/ai_assistant/pages/ai_chat_page.dart` 1,070.
- **Current impact:** Broad rebuild scopes (whole-page `setState`), unreviewable diffs, and effectively untestable UI logic.
- **Future risk:** These are the app's most-touched screens; each grows with every feature.
- **Recommendation:** Mechanical extraction into `presentation/widgets/` per feature; convert `setState`-heavy sections (receipt settings) to a Cubit with tightly-scoped `BlocBuilder`s (`buildWhen`). No behavior change required.

### AR-03 — UI pages invoke domain services directly, bypassing Bloc/UseCase
- **Priority:** P1 · **Effort:** M
- **Description:** Checkout — the single most critical flow — is orchestrated inside widgets: `features/products/checkout/product_checkout_page.dart:202` and `features/pos/presentation/pages/checkout_payment_page.dart:194` call `sl<CheckoutService>().completeSale(...)` directly from page code, including branch resolution and error handling. This contradicts the repo's own rule ("Widgets render UI and fire events only… zero side effects").
- **Current impact:** Two divergent checkout call sites to keep consistent; checkout logic (branch fallback, error mapping, receipt navigation) untestable without pumping widgets.
- **Future risk:** The two paths drift (they already differ in how they assemble deductions/items); a fix applied to one screen misses the other.
- **Recommendation:** One `CheckoutBloc`/`CompleteSaleUseCase` shared by both screens; widgets emit `SaleSubmitted` and render states. Same treatment for refund submission in `features/sales/presentation/widgets/refund_sheet.dart`.

### AR-04 — Service locator (`sl<…>`) used pervasively inside widgets and the router
- **Priority:** P2 · **Effort:** M
- **Description:** `app_router.dart` references `sl<…>` 30 times; pages resolve repositories/services ad hoc (`main_navigation_page.dart` ×6, `pos_terminal_page.dart` ×4). `AppRouter.router` is a `static final`, constructed at class-load with live singletons, making it impossible to instantiate the router with fakes.
- **Current impact:** Widget/router tests require booting the full DI graph; hidden dependencies aren't visible in constructors.
- **Future risk:** Locks the codebase out of widget-level testing precisely where regressions are most visible to users.
- **Recommendation:** Inject via constructors / `BlocProvider` at route boundaries; make the router a factory function `GoRouter buildRouter({required AuthBloc auth, required PermissionService perms, …})` so guards are testable. Keep `get_it` as the composition root only.

### AR-05 — Monolithic manual DI registration
- **Priority:** P3 · **Effort:** S–M
- **Description:** `core/config/di.dart` (596 lines) registers ~100 singletons in one function with 120+ imports.
- **Current impact:** Works today; merge-conflict magnet and no per-feature ownership.
- **Future risk:** Grows linearly with features; no lazy/feature-scoped composition for future modularization (e.g., disabling procurement entirely for a lean build).
- **Recommendation:** Split into `registerCoreModule(sl)`, `registerPosModule(sl)`, … in each feature folder; `initDI()` composes them. Optionally adopt `injectable` codegen later — not required.

### AR-06 — Feature-layer inconsistency is intentional but undocumented per feature
- **Priority:** P3 · **Effort:** S
- **Description:** Some features are fully layered (`auth`, `products`: data/domain/presentation with usecases), others are page+cubit only (`drafts`, `alert`), and some put repositories directly in `data/` without domain interfaces mirrored consistently (e.g., `features/reports/data/reports_repository.dart` at 868 lines mixes query building, aggregation, and period math). CLAUDE.md sanctions "follow the neighbor," but there is no marker of which tier a feature is in.
- **Current impact:** Contributors guess; reviews litigate structure repeatedly.
- **Future risk:** Gradual erosion into ad-hoc structure.
- **Recommendation:** One line in each feature's folder (README or a comment in the barrel file) declaring its tier; split `reports_repository.dart` by domain area (sales, inventory-health, expenses).

---

## 2. Reliability

### RL-01 — Offline startup can sign the user out locally on a *network* failure
- **Priority:** P0 · **Effort:** S–M
- **Description:** `bootstrap.dart:191-201`: when a cached session's access token has <60 s left, `refreshSession()` is awaited; **any** exception — including `SocketException`/timeout on an offline device — triggers `signOut(scope: SignOutScope.local)`. The slow path (lines 218–231) has the same collapse: timeout → `refreshSession()` → any error → local sign-out. `AuthException` with `refresh_token_not_found` and a plain network failure are not distinguished.
- **Current impact:** A cashier opening the app after the token expired overnight, on a dead uplink, is dumped to the sign-in screen and cannot sign in (offline). The till is unusable despite all data being present in Drift. (Assumption: `supabase_flutter` surfaces network failures as thrown exceptions here — consistent with its documented behavior; not runtime-verified.)
- **Future risk:** This will present as sporadic "app logged me out and I lost my morning" reports that are nearly impossible to reproduce.
- **Recommendation:** Catch narrowly: only treat `AuthException` codes that provably mean *revoked/invalid refresh token* as sign-out; on network-class errors keep the session, mark it "unverified," proceed with cached Drift auth context (the offline cold-start path already exists via `PermissionService.loadFromCache`), and re-validate on next connectivity. Add a regression test with a faked auth client.

### RL-02 — Inventory deduction guard is `assert`-only; release builds fail silent
- **Priority:** P0 (one-line hardening) · **Effort:** S
- **Description:** `features/inventory/data/inventory_repository.dart:266-269` (`recordSaleDeductions`) and `319-322` (`reverseSaleDeductions`): `if (branchId == null) { assert(false, …); return; }`. Asserts are compiled out in release mode, so a null `branchId` records the sale (the caller's transaction commits) **with zero stock movement and zero error**.
- **Current impact:** Mitigated today — both checkout pages resolve a branch before calling (`product_checkout_page.dart:116-125`) — but `CheckoutService.completeSale` accepts `String? branchId`, so nothing in the type system prevents a new caller (e.g., the AI path at `ai_tool_service.dart:549`) from passing null.
- **Future risk:** Silent inventory drift traced back weeks later; indistinguishable from theft in the fraud module you're about to build (M1).
- **Recommendation:** `throw ArgumentError.notNull('branchId')` instead of assert+return, and make `branchId` non-nullable through `CheckoutService`/`RefundService`/`IInventoryRepository` signatures, resolving the fallback at the UI/Bloc boundary.

### RL-03 — No crash reporting, no error telemetry, no log aggregation
- **Priority:** P0 · **Effort:** M
- **Description:** 282 `debugPrint` call sites are the entire logging story. `main.dart` installs error handlers (good) but they terminate in `debugPrint`. `pubspec.yaml` contains no Sentry/Crashlytics/logging package. Sync failures set `SyncStatus.failed` with an error string in the row (`sync_error` column) — visible to no one unless a user finds the right screen.
- **Current impact:** Production failures (already shipping — v1.4.6+237, Play production track) are invisible. `ENABLE_ANALYTICS: "true"` in `build.sh` configures an env flag with no consumer found in `lib/` (assumption: dead flag).
- **Future risk:** At "thousands of businesses," support becomes guess-driven; sync-stuck devices accumulate silently.
- **Recommendation:** Add `sentry_flutter`; create `core/logging/app_logger.dart` with `debug/info/warn/error(feature, method, error, stackTrace)` preserving the existing `[Feature] Error in methodName` format; route `FlutterError.onError`/`PlatformDispatcher.onError` and every `catch (e, st)` warn/error to it; add a breadcrumb on each `SyncResult` with failure counts. Gate by `AppEnv` flavor.

### RL-04 — Retry backoff exists only for transactions and refunds
- **Priority:** P2 · **Effort:** S
- **Description:** `_shouldSkipForBackoff` (`sync_service.dart:2652`) is applied only in `_syncTransactions` (line 1032) and `_syncRefunds` (line 1225). Every other entity retries permanently-failing rows on **every** 60-second cycle (`init`, line 225) plus every connectivity flap, forever.
- **Current impact:** A poison row (e.g., an orphaned inventory level, an RLS-rejected employee edit) generates a failed network round-trip per table per minute per device, and re-inflates `sync_error` churn.
- **Future risk:** Server-side, thousands of devices × poison rows = sustained junk load; battery drain on device.
- **Recommendation:** Move the backoff check into the shared pending-row iteration (trivial once AR-01's registry exists; until then, replicate the two-line guard in each `_syncX`). Consider a `retry_count` column at the next schema bump for true exponential backoff — the comment at line 2645 already acknowledges this.

### RL-05 — `syncAll` result aggregation can mask partial failures; audit/receipt pushes are fire-and-forget
- **Priority:** P2 · **Effort:** S
- **Description:** `_syncReceiptSettings` and `_syncAuditLogs` (`sync_service.dart:491-492`) swallow their outcomes (`void`, errors logged only), so `SyncResult.success` can be `true` while audit logs are failing — and audit logs are a compliance artifact. The special-cased 42501 handling inside `_syncAuditLogs` (lines 2176–2179) exists because of this shape.
- **Current impact:** UI "all synced" states can be wrong for audit/receipt settings.
- **Future risk:** M1 (hash-chained audit) makes audit-sync integrity load-bearing; silent failure becomes unacceptable.
- **Recommendation:** Return `SyncResult` from both and fold them into the aggregate like every other entity.

### RL-06 — Web bootstrap continues after database initialization failure
- **Priority:** P2 · **Effort:** S–M
- **Description:** `bootstrap.dart:37-49`: on web, if `AppDatabase.ensureReady()` times out (5 s) the exception is caught and startup **continues**, on the theory that "the database will be retried on each operation." Every subsequent Drift call then fails individually, surfacing as scattered feature-level errors rather than one clear startup failure.
- **Current impact:** Worst-case web UX: an app that renders but where every screen errors differently. (Assumption: WASM/OPFS init failure is persistent for the session in most cases — typical for missing COOP/COEP headers or private-mode storage.)
- **Future risk:** Untriageable web bug reports.
- **Recommendation:** Distinguish slow-init (retry with longer timeout + splash) from hard failure (dedicated full-screen error with the existing Lottie pattern and a "retry" that re-runs `ensureReady`).

### RL-07 — `ConnectivityService` probe treats DNS-resolvable-but-degraded backends as online, and misses the `none→wifi` probe on web
- **Priority:** P3 · **Effort:** S
- **Description:** `core/sync/connectivity_service.dart:46-52`: a HEAD to `/auth/v1/health` with any status code (`statusCode > 0`) counts as online — a 500-ing backend still triggers full sync attempts (each will fail per-entity). Minor; the debounce (800 ms) and design are otherwise sound.
- **Current impact:** Occasional wasted sync cycles during backend incidents.
- **Recommendation:** Treat 5xx as "reachable but degraded" and skip the sync trigger (or add jittered retry). Low priority.

### RL-08 — Drift local migrations swallow failures with `try/catch → debugPrint` in ~25 steps
- **Priority:** P1 · **Effort:** M
- **Description:** `core/database/app_database.dart` (schema v51): most `onUpgrade` steps wrap `ALTER TABLE` in try/catch that logs and continues ("column likely already exists"). The v44 step (lines 758–784) is a *confession*: a device shipped at schema 43 **without** the `restocked` column because a swallowed catch hid a real failure, and a checked backfill had to be written after the fact. v46 (lines 802–830) wraps a **data-transforming** step (`stock = stock_decimal`, then `DROP COLUMN`) in the same swallow-and-continue pattern — if the UPDATE fails, the DROP is skipped but the app proceeds on schema 51 with a divergent physical schema.
- **Current impact:** Migrations "succeed" on devices where they didn't; physical schema drift across the install base is undetectable.
- **Future risk:** Each future version multiplies drift permutations; the v44-style forensic fix becomes routine.
- **Recommendation:** (1) Replace blind try/catch with `pragma_table_info` existence checks (the v44 pattern) for idempotency. (2) Adopt drift's step-by-step migration testing (`drift_dev` schema snapshots) so v(N)→v(N+1) is CI-verified against real fixture DBs. (3) After `onUpgrade`, run `validateDatabaseSchema()` (drift's built-in) in debug builds — the repo already ships an "in-app schema validator" per the v41 comment; wire it to telemetry (RL-03).

---

## 3. Data Integrity

### DI-01 — All monetary amounts are IEEE-754 doubles
- **Priority:** P1 (decision) / P2 (migration) · **Effort:** XL
- **Description:** `RealColumn` for `totalAmount`, `discountAmount`, `taxAmount`, `subtotal`, `amountReceived`, `changeDue` (`core/database/tables/transactions_table.dart:17-32`), `unitPrice`, `lineTotal`, `lineTax` (`transaction_items_table.dart:12-16`), refunds, expenses, POs. Downstream arithmetic divides and re-multiplies (`refund_service.dart:124-127`: `unitTotal = lineTotal / qty; lineAmount = unitTotal * qty`) and compares with epsilons (`1e-6` at `refund_service.dart:119, 226` and `sync_service.dart:1304`).
- **Current impact:** Sub-centavo drift in split refunds and tax lines; totals that don't reconcile to the centavo across devices after LWW; float equality guards scattered ad hoc.
- **Future risk:** BIR accreditation (`UPSENSO_BIR_COMPLIANCE.md`) and the fraud module (M1) both require books that sum exactly. Retrofitting later multiplies the migration cost by every new table added in between (CRM invoices, subscriptions).
- **Recommendation:** Decide now, migrate incrementally: store minor units as `int` (`IntColumn` locally, `bigint` on Postgres — note Supabase columns are `numeric`, so server migration is a cast); introduce a `Money` value type with explicit rounding for tax/discount allocation (largest-remainder for line splits); convert at the model boundary so UI/PDF code changes minimally. Quantities sold by weight stay `double` — only currency changes.

### DI-02 — Offline invoice numbers are reassigned after collision, breaking receipt ↔ ledger identity
- **Priority:** P1 · **Effort:** M
- **Description:** Offline checkout claims a local `INV-…` (`invoice_number_service.dart:40-73`), prints it on the customer's receipt, then on sync a `23505` unique-violation triggers `reclaim()` which **replaces** the stored invoice number (`sync_service.dart:1111-1158`, `updateInvoiceNumber`). The paper receipt now cites an invoice number that belongs to a different sale (or none).
- **Current impact:** Two offline devices on the same business will collide routinely (both count up from the same synced watermark); refund-by-invoice lookup and any tax audit against printed receipts break for the reassigned sale.
- **Future risk:** Directly incompatible with BIR sequential-invoice requirements the roadmap commits to.
- **Recommendation:** Make issued numbers immutable. Options (pick one): (a) per-device series — embed a registered device/POS-terminal code in the number (`INV-D01-000123`), which BIR machine-registration conventions actually favor; (b) treat offline numbers as *provisional receipts* (clearly marked on the printout) and only issue final invoice numbers server-side, per the pre-accreditation mode already designed in `UPSENSO_BIR_COMPLIANCE.md` §9; (c) reserve number ranges per device while online. Also stop deriving the local counter from the last *seen* server value alone (`syncFromServer`) — that is what guarantees two offline devices collide.

### DI-03 — Local stock clamps at zero while the server applies signed deltas — local and server can diverge
- **Priority:** P2 · **Effort:** M
- **Description:** Locally, `InventoryLevelsDao.adjustQuantity` clamps to `[0, 999999]` (`inventory_levels_dao.dart:107`), and `StockMovementService` records `quantityAfter` using the same clamp (`stock_movement_service.dart:52`). Server-side, `maintain_inventory_level()` applies the raw delta with **no clamp** (`20260627000012_…sql:106-107`), so the authoritative level can go negative while every device shows 0, and each device's `quantity_before/after` ledger snapshots disagree with the server's running sum.
- **Current impact:** After any oversell race (two offline devices selling the last unit), devices display 0, server shows −1, and the pull (which upserts server rows into the local cache) then *un-clamps* the local view — inconsistent history in `stock_ledger` snapshots remains permanently.
- **Future risk:** The M1 fraud engine will read `quantity_before/after` as evidence; clamped snapshots produce false positives/negatives.
- **Recommendation:** Remove the local clamp (allow negative levels; they are truthful and the UI can badge them "oversold"), or clamp identically on the server. Truth must have one shape. Add a reconciliation report (server level vs. `SUM(ledger)`) as a scheduled Supabase function.

### DI-04 — Non-delta pull upserts can resurrect or double-apply state for mutable entities without pending-guards
- **Priority:** P2 · **Effort:** M
- **Description:** Full pulls for expenses, suppliers, POs, PO lines, goods receipts, recipe lines (`sync_service.dart:1859-2058`) upsert every server row each cycle. Only the employees pull checks for local pending changes before overwriting (`_hasPendingEmployeeChanges`, lines 1936-1939). Whether the other DAOs' `upsertFromServer` guard pending rows could not be verified for all 10+ DAOs in this review — **assumption:** at least some do not (the employees special-case existing at the call site suggests the guard is not uniformly inside DAOs).
- **Current impact:** A 60-second window race: user edits a supplier offline-queued → pull overwrites the local row with the stale server copy → push then uploads… whichever survived. With LWW server-side this self-corrects *only if* `client_updated_at` is respected on every table (it is on products/variants — `20260619000008_add_client_updated_at_for_lww.sql` — but expense status updates go through `updateExpenseStatus` with no LWW token, `sync_service.dart:1349-1356`).
- **Future risk:** Approval races on expenses/POs: two managers offline-approve/reject; last push wins with no conflict log (the `_logSupersededConflict` path exists only for products/variants).
- **Recommendation:** (1) Audit every `upsertFromServer` for a `sync_status != synced` guard; make it a required part of the `EntitySyncer` contract (AR-01). (2) Extend `client_updated_at` LWW + superseded-conflict logging to expenses, suppliers, POs. (3) For approval state machines (expense/PO status), prefer server-side state-transition RPCs over blind column upserts — an *approve* is not a *write*, it's a transition with preconditions.

### DI-05 — `clearLocalData` wipe-set is hand-maintained and already incomplete
- **Priority:** P2 · **Effort:** S
- **Description:** `sync_service.dart:260-296` clears 22 tables but not `employee_permissions`, `business_modules`, `procurement_settings`, `refund_settings`, `invoice_sequences`, `po_number_sequences`, or `business_templates`. The pending-count guard (`pendingSyncCount`, lines 301–320) likewise omits goods receipts/GR items (they *are* pushed and watched but not counted), so a logout could wipe pending GR rows the guard never saw. (`getPendingSync` exists for GRs — they're pushed at line 496 — but are absent from the `Future.wait` list.)
- **Current impact:** Data hygiene: the previous user's permission matrix and module states persist in Drift after logout on a shared device. The GR gap means the "refuse to wipe with unsynced data" guarantee has a hole.
- **Future risk:** Every new table risks being forgotten in one of the three hand-lists (wipe, count, watch).
- **Recommendation:** Fix the GR omission now (S); fold wipe/count into the per-entity registry (AR-01) so omission becomes structurally impossible.

### DI-06 — Transaction status has two writers (derived + pushed) — self-heal exists but the push is redundant risk
- **Priority:** P3 · **Effort:** S
- **Description:** Refunds flip `transactions.status` locally and push a status-only update (`sync_service.dart:1039-1060`), while `_recomputeTransactionStatusFromRefunds` (lines 1293–1311) re-derives the same status from refund quantities after every pull. Two sources of truth for one column; the derivation is correct and idempotent, the push can race it.
- **Current impact:** None observed — the self-heal converges. Complexity cost only.
- **Recommendation:** Derive status on the server too (trigger on `refund_items`, like inventory) and drop the status push entirely; one fewer pending-update pathway.

### DI-07 — Audit logs are queued client-side and can be lost with the device
- **Priority:** P2 · **Effort:** M (design exists)
- **Description:** All audit entries are local-first (`AuditLogService.log` → Drift → background push). Server-side immutability is enforced once rows arrive (`20260627000006_enforce_settings_and_audit_immutability.sql`), but entries pending upload on a lost/reset/wiped device are gone, and a malicious actor with device access can delete the SQLite file before sync. Fire-and-forget swallowing (`audit_log_service.dart:129-132`) means the app can't distinguish "logged" from "dropped."
- **Current impact:** Acceptable for operational logs; weak for the fraud/audit-chain ambitions.
- **Future risk:** M1's hash-chained design (`UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md`) presumably addresses this — implement it before marketing audit logs as tamper-evident.
- **Recommendation:** Prioritize the M1 hash-chain (device-sequence numbers + chained hashes make gaps *detectable* even when entries are unrecoverable); until then, push audit logs opportunistically at write time when online rather than only on the 60 s cycle.

---

## 4. Access Control & Data Protection

**Overall:** this is the strongest area of the codebase. The two-layer client model (`PermissionService` module gate + per-employee matrix with role fallback), the router guards (`app_router.dart:174-200`), enforcement inside services (`RefundService` checks `pos.refund_sale` itself, `refund_service.dart:71`), and 97 migrations of server-side RLS (restrictive policy layering, `SECURITY DEFINER` helpers with `search_path` pinned, bcrypt manager-PIN + single-use server-issued refund authorizations, role-escalation guards, owner-removal protection, storage-bucket scoping) reflect a real "hidden UI is not access control" discipline. Findings below are residual.

### SEC-01 — Local database is unencrypted at rest; logout leaves permission/module residue
- **Priority:** P1 · **Effort:** M
- **Description:** Drift runs on plain SQLite (`sqlite3_flutter_libs`; OPFS/IndexedDB on web). Full financial history (sales, margins, cost prices), employee PII, and audit logs are readable by anyone with filesystem access to the device. `SecureStorageService` protects only the small auth-context blob. Combined with DI-05, a logout leaves the prior user's permission matrix in `employee_permissions`.
- **Current impact:** Lost/stolen Android terminal = full business-data disclosure. Android app-sandbox mitigates casual access but not rooted/extracted devices; desktop targets have no sandbox at all.
- **Future risk:** Philippine Data Privacy Act exposure (the repo's own M-LEGAL gate) once employee PII is on thousands of devices.
- **Recommendation:** Adopt SQLCipher (`sqlcipher_flutter_libs` is a drop-in for drift) with a key held in `flutter_secure_storage`/Keystore on mobile/desktop; document the web storage model as browser-sandboxed (SQLCipher isn't available there). Complete the logout wipe (DI-05).

### SEC-02 — `PermissionService` fails open for unknown modules and pre-load core modules
- **Priority:** P2 · **Effort:** S (documentation + one decision)
- **Description:** `permission_service.dart:312-324`: before module state loads, `pos`/`inventory` are enabled (deliberate, documented, correct for a till); after load, a module code **absent** from the map defaults to *enabled*. Newly shipped modules therefore appear for every business until the business explicitly disables them — the inverse of a subscription/limits posture (M7 will sell modules).
- **Current impact:** Minor today (modules are seeded per business — `20260612000010_seed_new_modules.sql`).
- **Future risk:** When modules become paid entitlements, absent-means-enabled is a monetization bypass; server RLS gates permissions, not module entitlements.
- **Recommendation:** Before M7: flip absent-module default to *disabled* for non-core modules, and enforce module entitlement server-side (RLS or RPC), not only in the client gate.

### SEC-03 — AI assistant tool layer builds SQL with string interpolation of clause fragments
- **Priority:** P2 · **Effort:** S
- **Description:** `features/ai_assistant/services/ai_tool_service.dart:36-57` composes WHERE-clause fragments (`branchFilter`) into raw `customSelect` SQL. All *values* go through `Variable` placeholders (parameterized — good); the risk is structural: the pattern invites a future contributor to interpolate a value directly, and the tool layer executes with the local DB's full visibility, scoped only by the `businessId/cashierId/branchId` the caller passes. No `PermissionService`/`DataScopingLayer` check exists inside `AiToolService`; scoping correctness depends entirely on every caller in the AI pipeline.
- **Current impact:** No injection found; local-DB blast radius only (RLS still guards the server). But a permission-bypass: a cashier without `reports.view_all` could, via the assistant, aggregate all-branch sales *from locally cached data* if the pipeline passes a null branch. (Assumption: local cache may contain rows broader than the user's scope, since pulls are business-wide; server SELECT scoping added in `20260627000014` limits what a *cashier's own token* pulls, which mitigates this on single-user devices but not on shared terminals where an owner previously synced.)
- **Future risk:** The M2 insights work multiplies query surface.
- **Recommendation:** Route every `AiToolService` read through `DataScopingLayer` (it exists and is tested — `test/core/permissions/data_scoping_layer_test.dart`); centralize scope resolution inside the service (inject `PermissionService`), not at call sites.

### SEC-04 — Session/tenant integrity mechanisms are strong — keep the invariants tested
- **Priority:** P3 · **Effort:** S
- **Description:** Positive finding with a follow-up. `ActiveBusinessContext` as sole tenant authority, `resolveSyncBusinessId` (pure, tested), `pullFromServer`'s tenant guard (`sync_service.dart:1630-1637`), `AuditLogService`'s cross-tenant drop (`audit_log_service.dart:95-103`), and the 42501 self-heal handshake collectively close the shared-device stale-tenant hole. These invariants live in comments and two pure functions.
- **Recommendation:** Add an integration-style test that simulates account switch with queued pendings (the exact race the comments describe) so the invariant survives the AR-01 refactor.

---

## 5. Performance

### PE-01 — Full-table pulls for 8+ entities on every 60-second cycle and every connectivity change
- **Priority:** P1 · **Effort:** M
- **Description:** `SyncService.init` (lines 207–228) triggers `syncAll` on start, on every connectivity restore, and every 60 s. `pullFromServer` uses the keyset delta (`_pullIncremental`) only for products, variants, inventory levels, stock ledger, transactions, refunds, audit logs. Categories (line 1649), expenses (1859), branches (1874), employees (1927), suppliers (1984), POs (1998), PO lines (2012), goods receipts+items (2026-2039), recipe lines (2047) re-download the **entire** table each pass and re-upsert every row locally.
- **Current impact:** For a business with 5,000 expenses and 50 POs, each device re-downloads and re-writes those rows ~1,440×/day. Supabase egress cost + device battery/data + SQLite write amplification.
- **Future risk:** Linear in businesses × devices × rows; this is the first thing that will fall over at "thousands of businesses."
- **Recommendation:** All pulled tables already have `updated_at` (`20260614000001_add_updated_at_softdelete_delta_sync.sql`) — extend `_pullIncremental` to each (the plumbing is generic already). Lengthen the periodic timer (e.g., 5 min with jitter) once push-on-write is reliable, keeping the immediate sync on connectivity-restore and on local writes.

### PE-02 — Push path is one-row-per-request, sequential
- **Priority:** P2 · **Effort:** M
- **Description:** Every `_syncX` loops `for (record in pending)` awaiting one PostgREST request per row (plus one `updateSyncStatus` write each). A 200-sale offline day = 200+ sequential round-trips at reconnect, ~2 requests per sale (header + items) plus per-row status updates.
- **Current impact:** Slow catch-up sync on poor links (the exact environment offline-first targets); the 60 s timer can overlap intent with long catch-ups (guarded by `_isSyncing`, so cycles are skipped, not overlapped — correct but slow).
- **Recommendation:** Batch: PostgREST `upsert` accepts arrays (already used for `upsertTransactionItems`). Push per-entity in pages of 50–100 with a single status update per page. Order-dependent rows (tx → refund) keep the existing sequencing between entities.

### PE-03 — Report/dashboard aggregation loads row sets into Dart instead of aggregating in SQL
- **Priority:** P2 · **Effort:** M
- **Description:** `features/dashboard/data/dashboard_repository.dart:153` (`getAllTransactionsSince` → in-memory fold) and `features/reports/data/reports_repository.dart:319, 337` (all transactions/refunds since cutoff into memory). With a year of sales at a busy till (50k+ transactions), these lists get large on low-end Android hardware.
- **Current impact:** Fine at current volumes; measurable jank risk at 10k+ rows (assumption: not profiled in this review).
- **Recommendation:** Push aggregation into SQL (`customSelect` with `SUM/GROUP BY` — the AI tool service already does this correctly, e.g. `getSalesTotal`); paginate any raw-row listing. Add `EXPLAIN`-informed indices for the hot local queries (transactions by `(business_id, created_at)` exists server-side; verify Drift-side indices for the report ranges).

### PE-04 — `watchTotalPendingSyncCount` maintains 17 always-on Drift watch queries
- **Priority:** P3 · **Effort:** S
- **Description:** `sync_service.dart:326-446`: 17 concurrent `watchPendingSyncCount()` streams (17 live SQLite queries re-run on any table change) merged by hand to render one badge number.
- **Current impact:** Modest constant overhead; the hand-rolled merge is correct (closes subscriptions on cancel) but is 120 lines for one integer.
- **Recommendation:** Single `customSelect` UNION query (`SELECT COUNT(*) FROM (… UNION ALL …)`) watched once — one stream, one query; or `Rx.combineLatest`. Fold into AR-01.

### PE-05 — Whole-page `setState` in the heaviest screens
- **Priority:** P2 · **Effort:** (covered by AR-02)
- **Description:** `receipt_settings_section.dart` (23 `setState` over 2,731 lines), `pos_terminal_page.dart` (6), sidebar state in `main_navigation_page.dart` — each rebuilds very large subtrees per keystroke/toggle.
- **Recommendation:** As AR-02: cubits + scoped builders; `const` constructors for the static regions (cheap win in the sidebar's 10 private widget classes).

---

## 6. Code Quality

### CQ-01 — Test coverage is ~1.7% of files; the money paths are untested
- **Priority:** P0 (start now, continuous) · **Effort:** XL (incremental)
- **Description:** 9 test files / ~1,070 LOC total: formatters, permission service (good, 277 LOC), data scoping, audit (service, DAO, repo), refund-service *pre-transaction guards only* (the mock DB means the transactional body is never executed), one cubit, AI analytics. Zero tests for: `SyncService` (2,712 lines), `CheckoutService`, `StockMovementService`, `InvoiceNumberService`, any Drift DAO except audit, any migration step, any Bloc except one, any widget.
- **Current impact:** Refactors AR-01/DI-01 are high-risk without a safety net; regressions in checkout/sync ship undetected (see CI PR-01).
- **Recommendation:** Priority order: (1) in-memory Drift (`AppDatabase.forTesting(NativeDatabase.memory())`) tests for `CheckoutService.completeSale` (oversell abort, atomicity), `RefundService.refund` (over-refund, restock branch-pinning), `StockMovementService.apply` (ledger/level/variant consistency); (2) DAO sync-status transition tests; (3) `SyncService` characterization tests with a fake remote before AR-01; (4) migration tests v16→v51 via drift_dev schema tooling; (5) bloc_test for AuthBloc's logout/tenant-reject paths.

### CQ-02 — Duplicated per-entity sync code (~1,500 lines of structural copy-paste)
- **Priority:** P1 · **Effort:** (same work as AR-01)
- **Description:** The 17 `_syncX` methods differ only in DAO/remote-DS calls and special-case recovery; `syncAll`'s triple aggregation lists every entity three times; `pullFromServer` repeats an identical try/catch/log/errors-add block 15 times. Line 599 builds an 18-clause message string by hand.
- **Recommendation:** AR-01's registry eliminates the class; until then, freeze the pattern (no new copy-paste entities).

### CQ-03 — Mixed-language and low-value comments in core files
- **Priority:** P3 · **Effort:** S
- **Description:** Taglish comments in `sync_service.dart` (`// upload na here  bag o i pull` line 474, `// i sync na yung categories` 703, `// check kapag may internet connection` 322, `pull the data from sever kapag bago ang device …` 1628). Fine for a personal repo; a liability the moment a second maintainer or an auditor (BIR accreditation involves source review) reads the sync engine. Elsewhere comment quality is excellent (the RLS migrations are exemplary).
- **Recommendation:** English-only in `core/`; sweep opportunistically during AR-01.

### CQ-04 — Dead/dangling flags and duplication in config
- **Priority:** P3 · **Effort:** S
- **Description:** `ENABLE_ANALYTICS` and `LOG_LEVEL` are written into build flavors (`build.sh`) with no consumer found under `lib/` (assumption: grep-verified absence of readers beyond `app_env.dart` declaration). `iconly` is both a hosted dep and a path override (`packages/iconly`).
- **Recommendation:** Remove or wire them (LOG_LEVEL becomes real with RL-03's logger).

### CQ-05 — Naming and structure conventions are otherwise strong
- **Priority:** — (positive)
- **Description:** Consistent `i_x_repository` interfaces, `*_remote_ds`/`*_dao` split, `PermissionKeys` as the single permission-string source with a CI-runnable matrix differ (`tool/diff_matrices.dart`), `core/widgets/` reuse discipline, `SyncStatus` extension with safe corrupt-value fallback (`sync_status.dart:40-62`). No raw `print()` anywhere. Zero TODO/FIXME markers — which cuts both ways: nothing is tracked in-code; known gaps live only in `docs/permission_hardening_followups.md` and commit messages.

---

## 7. Production Readiness

### PR-01 — CI ships every `main` push straight to Play Store production with no quality gate
- **Priority:** P0 · **Effort:** S
- **Description:** `.github/workflows/deploy.yml`: checkout → build appbundle → `upload-google-play` with `tracks: production`, `status: completed`. No `flutter analyze`, no `flutter test`, no `dart run tool/diff_matrices.dart`, no build for the web target, no PR-triggered checks at all (the only workflow is the deploy). A merge with a failing test or even a compile-breaking file in an untouched-by-CI path ships to all users; Play review latency is the only buffer.
- **Current impact:** The repo's own execution doc admits code has been merged unverified ("The remote env has no Flutter SDK, so analyze/test were NOT run").
- **Recommendation:** (1) Add a `checks.yml` on `pull_request` + `push`: `flutter analyze --fatal-infos`, `flutter test`, `dart run tool/diff_matrices.dart`, web build smoke. (2) Make `deploy` depend on it. (3) Change the Play track to `internal` (or `production` with `userFraction` staged rollout) and promote manually. (4) Add a migration-diff check: fail CI if a Drift table changed without a `schemaVersion` bump.

### PR-02 — No monitoring, alerting, or support tooling
- **Priority:** P0 · **Effort:** M
- **Description:** Beyond RL-03 (crash reporting): there is no way to answer "which devices are stuck with `sync_status = failed` rows," "what fraction of syncs succeed," or "which businesses are on which app version." No Supabase log-based alerting is configured in-repo; no release-health tracking (obfuscated builds *do* upload split-debug-info to nowhere — the symbols directory is a build artifact only, so even ad-hoc stack traces from users are unsymbolicated).
- **Recommendation:** Sentry release health + dSYM/mapping upload in CI; a tiny `device_health` heartbeat row (app version, pending count, last sync ok) pushed daily per device gives fleet visibility with one table; a Supabase scheduled function alerting on audit-log or transaction ingestion anomalies.

### PR-03 — No backup/restore or data-export story for tenants
- **Priority:** P1 · **Effort:** M
- **Description:** `scripts/backup_db.sh` backs up a dev database. There is no per-business export (sales CSV, BIR books), no documented Supabase PITR posture, and no local-DB backup before destructive Drift migrations (e.g., v46's column collapse mutates then drops with no local backup file).
- **Recommendation:** Document/enable Supabase PITR for prod; add "export my data" (CSV per entity) — also a Data Privacy Act obligation; snapshot the SQLite file before any `onUpgrade` that rewrites tables (copy file, delete on success).

### PR-04 — Single environment/flavor pipeline; no staging backend visible
- **Priority:** P2 · **Effort:** M
- **Description:** CI builds only `prod.json` from a secret. There is no staging Supabase project referenced, so migrations (97 and counting) presumably apply to production directly (assumption: no `supabase/config.toml` branching or preview-branch workflow found in-repo).
- **Recommendation:** Use Supabase preview branches (the MCP/CLI supports them) or a dedicated staging project; require migrations to pass on staging + a smoke sync from a debug build before prod apply.

### PR-05 — Release discipline exists (versioning, obfuscation, keystore runbook) — build on it
- **Priority:** — (positive with follow-ups)
- **Description:** Version bump discipline (`1.4.6+237`), obfuscated builds with split-debug-info, a keystore rotation runbook (`docs/SECURITY_keystore_rotation_runbook.md`), and Cloudflare Pages web deploy are all present.
- **Recommendation:** Attach the debug-info artifacts to a release (or Sentry) so obfuscation doesn't equal unsupportability; tag releases in git (no tags found).
