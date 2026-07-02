# UPSENSO — Production-Readiness Review: Executive Summary

**Review date:** 2026-07-02
**Scope:** Full codebase — 534 Dart files (`lib/`), 97 Supabase migrations, 9 test files, CI/CD, docs.
**Reviewed as:** Principal Flutter Architect / Staff Engineer / AppSec Reviewer / QA Lead.
**Method note:** The remote review environment has no Flutter SDK, so `flutter analyze` / `flutter test` were **not** executed; all findings are from static reading of the code. Where a finding depends on runtime behavior, that assumption is stated explicitly in `findings.md`.

---

## Scores

| Dimension | Score (0–100) | One-line rationale |
|---|---|---|
| **Architecture** | **74** | Clean layering, DI, and an unusually mature permission/RLS design — undermined by a 2,712-line sync monolith, 1,500–2,700-line widget files, and UI pages calling services directly. |
| **Reliability** | **66** | Thoughtful failure recovery in sync (FK self-healing, invoice re-claim, tenant self-heal) — but zero crash reporting, `debugPrint`-only logging, and an offline startup path that can sign a user out locally. |
| **Maintainability** | **58** | Consistent conventions and excellent internal docs, but ~1.7% of files have tests, the sync engine requires ~8 edits per new entity, and several files violate the project's own 40-line-function / single-responsibility rules by an order of magnitude. |
| **Production readiness** | **52** | Every push to `main` ships **directly to the Play Store production track with no analyze/test gate**, there is no crash/error telemetry, no staged rollout, and no monitoring story. The app is *shipping* (v1.4.6+237) but is not operationally *ready*. |

**Overall: NOT production-ready for scale.** The domain core (checkout, refunds, stock ledger, permissions, RLS) is genuinely strong — better than most codebases at this stage. The gaps are almost entirely in the *engineering system around the code*: verification, observability, test coverage, and the sync engine's ability to scale past a handful of entities and devices.

---

## Top 10 Highest-Priority Issues

| # | ID | Issue | Why it's top-10 |
|---|---|---|---|
| 1 | PR-01 | **CI deploys to Play Store production on every `main` push with no `flutter analyze`/`flutter test` gate** (`.github/workflows/deploy.yml`). | One bad merge = broken build in every customer's hands. Cheapest possible fix, highest possible leverage. |
| 2 | PR-02 | **No crash reporting or error telemetry anywhere.** 282 `debugPrint` call sites are the entire observability story; release-build errors vanish. | You cannot support real businesses' financial operations blind. Sync failures marked `SyncStatus.failed` are invisible to the operator and to you. |
| 3 | QA-01 | **9 test files (~1,070 LOC) for 534 source files.** No tests for `SyncService`, `CheckoutService`, DAOs (except audit), migrations, or any BLoC except one cubit. | Financial + inventory correctness currently depends on manual testing. CLAUDE.md's own bar ("a feature is not done until its critical paths have coverage") is not met. |
| 4 | DI-01 | **All money is IEEE-754 `double`** (`RealColumn` in `transactions_table.dart:17-32`, `transaction_items_table.dart:12-16`; epsilon hacks like `1e-6` in `refund_service.dart:119`). | Accumulating rounding errors in totals, tax, and refund splits (`lineTotal / qty * qty`). For a system with BIR-compliance ambitions this is a structural defect. |
| 5 | RL-01 | **Offline startup can locally sign the user out** — `bootstrap.dart:191-201/222-229`: if the access token is near expiry and the device is offline, `refreshSession()` throws a *network* error which is treated as an invalid refresh token → `signOut(scope: local)`. | An offline-first POS that locks the cashier out at open-of-day when the router is down defeats its core promise. Pending sales stay in Drift but the till is unusable. |
| 6 | AR-01 | **`SyncService` is a 2,712-line monolith with 34 constructor dependencies.** Each new synced entity needs ~8 hand-edits (push method, result aggregation ×3, pull block, pending count, watch counter, clearLocalData). | This is the scaling choke point for both team velocity and correctness — several past bugs visible in the git/migration history live exactly here. |
| 7 | PE-01 | **Several tables are full-table-pulled on every sync cycle (60 s timer + every connectivity change):** categories, expenses, employees, suppliers, POs, PO lines, goods receipts, recipe lines (`sync_service.dart:1649, 1859-2058`). Only 7 entities use the delta watermark. | At thousands of businesses this multiplies Supabase egress and device battery/data by orders of magnitude. The delta mechanism already exists — it's just not applied everywhere. |
| 8 | DI-02 | **Invoice numbers can silently change after the receipt is printed.** Offline-claimed `INV-…` collides on sync → `reclaim()` assigns a new number (`sync_service.dart:1107-1167`). The customer's paper receipt no longer matches the stored/reported invoice. | Direct conflict with the sequential-invoice/BIR compliance goal in `docs/UPSENSO_BIR_COMPLIANCE.md`; also breaks refund-by-receipt lookups. |
| 9 | RL-02 | **Release-mode guard stripping in inventory writes.** `inventory_repository.dart:266-269, 319-322`: `assert(false)` + silent `return` when `branchId == null` — in release builds a sale would commit **with no stock deduction and no error**. | Currently mitigated by callers always resolving a branch, but it is a one-refactor-away silent inventory-corruption trap in the money path. |
| 10 | SEC-01 | **Local financial data at rest is unencrypted** (plain SQLite via `drift_flutter`/`sqlite3_flutter_libs`; IndexedDB/OPFS on web), and `clearLocalData` (`sync_service.dart:260-296`) does **not** wipe `employee_permissions`, `business_modules`, or invoice/PO sequence tables on logout. | Sales, margins, employee data, and a former user's permission matrix persist readable on a lost/shared device. |

---

## Top 10 Improvement Opportunities

| # | Opportunity | Payoff |
|---|---|---|
| 1 | **Add a CI quality gate** (analyze + test + `dart run tool/diff_matrices.dart`) required before the deploy job, and switch Play upload from `production/completed` to an internal/staged track with progressive rollout. | Eliminates the single biggest ship-a-broken-build risk in an afternoon. |
| 2 | **Adopt Sentry (or Crashlytics) + a thin `AppLogger`** that wraps the existing `[Feature] Error in method: $e\n$st` convention and forwards warn/error to telemetry. The log-format discipline already in the codebase makes this nearly mechanical. | Turns 282 blind `debugPrint`s into an operational signal; makes `SyncStatus.failed` rows visible before the customer notices. |
| 3 | **Refactor `SyncService` into a registry of `EntitySyncer`s** (push/pull/pendingCount/clear per entity behind one interface, iterated by a small engine). | Turns 8-edits-per-entity into 1 class per entity; makes sync unit-testable; deletes ~1,500 lines of copy-paste. |
| 4 | **Extend the `_pullIncremental` watermark to every pulled entity** and batch pushes (Supabase `upsert` accepts row lists — already used for transaction items). | 10–100× less sync traffic per device; O(changed) instead of O(all) per 60 s cycle. |
| 5 | **Migrate money to integer minor units** (centavos) with a `Money` value type at the edges. Do it table-by-table starting with new writes + a Drift/Postgres migration for `transactions`/`transaction_items`/`refunds`. | Exact arithmetic for totals/tax/refunds; kills the `1e-6` epsilon class of bugs; prerequisite for credible BIR accreditation. |
| 6 | **Build the test pyramid where the money is:** in-memory-Drift tests for `CheckoutService`, `RefundService`, `StockMovementService`, and DAO sync-status transitions; a `SyncService` contract test with a fake remote; Drift migration tests (drift_dev's schema-test tooling) for the v16→v51 upgrade chain. | Converts the highest-risk logic from "manually verified" to regression-protected; unblocks confident refactoring of items 3–5. |
| 7 | **Treat offline token expiry as a soft state:** on network-type errors during `refreshSession()`, keep the local session and Drift cache active in a "degraded/unverified" mode and retry on connectivity, instead of `signOut(local)` (`bootstrap.dart`). | Preserves the offline-first guarantee where it matters most — opening the till. |
| 8 | **Split the widget monoliths** (`receipt_settings_section.dart` 2,731 lines, `main_navigation_page.dart` 1,625, `employee_permissions_page.dart` 1,804, `po_form_page.dart` 1,658, `pos_terminal_page.dart` 1,402) into `widgets/` subfiles; move the checkout orchestration out of `product_checkout_page.dart:202` / `checkout_payment_page.dart:194` into a Bloc/UseCase per the project's own architecture rule. | Restores the repo's stated standards; shrinks rebuild scopes; makes the POS screen testable. |
| 9 | **Make invoice numbers immutable once issued:** claim server numbers eagerly when online; when an offline number collides, keep the printed number as the legal identifier (per-device series or suffix, e.g. `INV-000123-D2`) instead of reassigning, or gate final invoice issuance on the BIR pre-accreditation mode design in §9 of `UPSENSO_BIR_COMPLIANCE.md`. | Receipt in the customer's hand always equals the ledger. |
| 10 | **Modularize DI and cut service-locator use in widgets** (`sl<…>` appears 30× in `app_router.dart` alone): per-feature `registerXModule(GetIt)` functions, constructor/BlocProvider injection in pages. | Faster onboarding, testable routing, smaller blast radius per feature change. |

---

## What is genuinely good (keep doing this)

- **Server-side inventory derivation** (`20260627000012_enforce_inventory_adjust_via_ledger.sql`): the ledger is the only way stock moves; client `quantity` writes are neutralized by trigger. This is the *correct* multi-device answer and most POS codebases never get here.
- **RLS depth and hygiene**: 97 migrations with restrictive+permissive policy layering, `SECURITY DEFINER` helpers, bcrypt manager-PIN with server-issued single-use refund authorizations, role-escalation guards, audit immutability. Each migration documents WHY + ROLLBACK.
- **Atomic financial services**: `CheckoutService.completeSale` and `RefundService.refund` wrap validation + writes in single DB transactions with real stock-availability checks and over-refund guards.
- **Sync failure recovery**: FK-violation self-healing (re-queue missing parents with orphan detection), duplicate-invoice recovery, tenant-rejection (42501) self-heal handshake with `AuthBloc`, keyset-cursor delta pulls that only advance watermarks after full page application.
- **Documentation**: `docs/` (architecture, schema, RLS, permissions, execution sequence with session-handoff footer) is exemplary.

The roadmap in `roadmap.md` sequences the fixes; `findings.md` carries the full evidence.
