# UPSENSO — Architecture Recommendations

Forward-looking design guidance. Assumes the target stated in the review brief: **thousands of businesses, multiple concurrent devices per business**, on the existing Flutter + Drift + Supabase offline-first stack. The stack choice itself is sound — nothing here proposes replacing it.

---

## 1. What to preserve (explicitly)

These are architectural assets. Refactors must not regress them:

1. **Ledger-derived inventory** (`20260627000012`): stock moves only via `stock_ledger`; server triggers derive levels/variant totals; client quantity writes are neutralized. This is the correct multi-writer convergence model — extend it (see §5), never bypass it.
2. **Single-transaction financial services** (`CheckoutService`, `RefundService`, `StockMovementService`): validation + all writes in one Drift transaction. Keep these as the *only* write paths for their domains; the AI tool layer already correctly reuses `CheckoutService`.
3. **Tenant-identity discipline**: `ActiveBusinessContext` as sole authority, pure tested guards (`resolveSyncBusinessId`), RLS as the real enforcement, 42501 self-healing. Keep the pure functions pure.
4. **Permission architecture**: `PermissionKeys` → `AppPermission` → `AppFeature` → dual matrices + `tool/diff_matrices.dart`, with server-side `has_permission()` mirroring. The 8-step "adding a feature" checklist in CLAUDE.md is unusually good process; automate step verification in CI instead of relaxing it.
5. **Migration documentation style**: every Supabase migration states WHY, APPROACH, ROLLBACK. Make this a hard convention for Drift steps too.

---

## 2. Target module structure

Current `lib/` is already feature-foldered; the problems are (a) `core/` accreting god-objects (sync), (b) presentation reaching into services, (c) no enforced dependency direction. Target:

```
lib/
  core/                      # pure infrastructure: db, env, logging, theme, widgets
    database/                # tables, daos, connection (unchanged)
    logging/                 # NEW: AppLogger (Phase 1)
    sync/
      engine/                # NEW: SyncEngine, EntitySyncer interface, SyncResult
      syncers/               # NEW: one file per entity (products_syncer.dart, …)
      connectivity_service.dart
    permissions/             # unchanged (it's good)
    services/                # cross-feature domain services (checkout, refund, stock)
  features/<name>/
    di.dart                  # NEW: registerXModule(GetIt sl) — feature owns its wiring
    data/    domain/    presentation/
  app/                       # NEW: composition root
    bootstrap.dart  router.dart  di.dart (composes feature modules)
```

Rules to adopt (and check in review):

- **Dependency direction:** `features/*` may import `core/*`; `core/*` must never import `features/*`. Today `core/sync/sync_service.dart` imports 12+ `features/*` data sources — the registry refactor fixes this naturally, because each `EntitySyncer` lives beside its feature's data layer and *registers into* core's engine, inverting the dependency.
- **Presentation rule:** widgets import blocs/cubits and entities only — never `*_service.dart`, `*_repository.dart`, or `sl<>` (allowed only in `app/` and feature `di.dart`). Enforceable with a simple CI grep or `dart_code_metrics`-style banned-imports config.
- **Feature tiers:** declare each feature "full" (data/domain/presentation) or "lite" (pages + cubit) in a one-line README per feature, so structure stops being re-litigated per PR.

---

## 3. The sync engine (the one big redesign)

**Problem recap:** `SyncService` hand-codes 17 entities × {push, pull, count, watch, wipe} with three parallel hand-maintained lists (already diverged — goods receipts are pushed and watched but not counted, so the logout-wipe guard is blind to them).

**Target design:**

```dart
abstract class EntitySyncer {
  String get entity;                       // 'products'
  int get pushOrder;                       // parents before children
  Future<SyncResult> pushPending(SyncContext ctx);
  Future<int> pull(SyncContext ctx);       // keyset delta via shared PullCursorStore
  Future<int> pendingCount();
  Stream<int> watchPendingCount();
  Future<void> clearLocal();
}
```

- A base `PushLoop` mixin owns the shared shape: iterate pending → backoff check → status switch → mark synced/failed → collect errors. Entity-specific recovery (variant FK re-queue, invoice reclaim-replacement, expense status transitions) becomes overridable hooks — today those recoveries are the *good* parts buried in copy-paste.
- `SyncEngine` (the renamed `SyncService`) keeps exactly what is genuinely cross-cutting: `_isSyncing` gate + `_pendingBusinessId` queueing, tenant guards, connectivity/timer triggers, result aggregation (a fold over the registry — deleting the 3×18-entity hand lists), and the 42501 handoff.
- `pendingSyncCount`, `watchTotalPendingSyncCount` (as one UNION query), and `clearLocalData` iterate the registry — a forgotten entity becomes **impossible**, which converts finding DI-05 from a recurring bug class into a non-issue.
- **Migration path:** one entity per PR behind characterization tests; suppliers first (no special cases), transactions last (most recovery logic). Total ≈ 10–14 PRs, each small and revertible.

**Pull side:** `_pullIncremental` is already the right abstraction (keyset `(timestamp, id)` cursor, watermark advanced only after full page application, child rows before cursor advance). Promote it into the engine and make *every* entity use it — the full-table pulls are the app's #1 scale liability (finding PE-01) and every server table already has `updated_at` + soft-deletes from `20260614000001`.

**Cadence:** move from "poll every 60 s" to "push on local write (debounced ~3 s), pull on connectivity-restore + long-interval timer with jitter (5 min ±60 s)". At thousands of devices this is the difference between O(fleet × minutes) requests and O(actual changes).

---

## 4. State management and presentation

- **One pattern per flow, enforced at the money paths first.** Both checkout pages currently orchestrate `CheckoutService` inline (finding AR-03). Introduce `CompleteSaleUseCase` + a single `CheckoutBloc` used by the POS terminal and product-checkout screens. The repo's Cubit-for-simple / BLoC-for-complex convention is fine — the violation is *where* logic lives, not which class is used.
- **Decompose by rebuild boundary, not by file size alone.** When splitting the five monolith files, cut along state boundaries: e.g., `receipt_settings_section.dart`'s 23 `setState`s map naturally to a `ReceiptSettingsCubit` with field-level state, and each settings card becomes a `const`-constructible widget with a scoped `BlocBuilder`+`buildWhen`.
- **Router as a function.** `AppRouter.router` static-final → `GoRouter buildRouter({required AuthBloc, required PermissionService, required SharedPreferences})`. The guard table (`routePermissionGuards`) is good design — keep it declarative, and unit-test it once the router is constructible with fakes.
- **Keep `PermissionGate`/module-gate reactivity** (`moduleGateRevision` merged into `refreshListenable`) — that pattern is correct and subtle; document it in `UPSENSO_ARCHITECTURE.md` so a refactor doesn't drop it.

---

## 5. Data architecture direction

1. **Money:** integer minor units + `Money` value type (findings DI-01, roadmap 3.5). Non-negotiable before BIR work. Quantities stay `double` (weight-sold products are legitimately fractional).
2. **Extend the "server derives, client proposes" pattern.** Inventory got this right. Apply the same shape to the other convergence-sensitive fields:
   - `transactions.status` ← derive from refund rows server-side (trigger), drop the client status push (finding DI-06).
   - Expense/PO approval ← server RPC state transitions with preconditions (`approve(id) WHERE status='pending'`), not blind column upserts (finding DI-04). Offline approvals queue the *intent* (an event row), not the resulting state.
   This is an incremental move toward event-shaped sync for the few state machines that need it — **not** a general event-sourcing rewrite, which this system does not need (transactions, refunds, stock ledger, audit logs are already append-only events; that's why sync works as well as it does).
3. **One truth-shape for stock:** remove the client-side clamp so local and server arithmetic agree (finding DI-03), and add a scheduled server reconciliation (`inventory_levels.quantity` vs `SUM(stock_ledger)`) as a permanent invariant check.
4. **Identifiers:** client-generated UUIDv4 everywhere is correct for offline-first — keep it. Invoice/PO numbers are the exception (human-facing, legally sequential): make them per-device series so issued numbers are immutable (finding DI-02).
5. **Schema evolution:** pair every Drift `schemaVersion` bump with a drift_dev schema snapshot + step test in CI; keep the Supabase migration as source-of-truth twin. Add a CI check that a change under `core/database/tables/` without a version bump fails.

---

## 6. Multi-tenant scalability posture

Current model — one Supabase project, RLS-isolated tenants, one Drift DB per device holding a single business — is the right architecture for this product class and will hold well past "thousands of businesses" **if** the sync-traffic work (Phase 5) lands. Specific guidance:

- **Do not shard prematurely.** Postgres with the existing per-business indexes (`20260628075906` keyset index pattern, `20260621000003` line-items business_id+created_at) will handle this comfortably; the bottleneck is chatty clients, not the database.
- **Watch two server hotspots:** `claim_invoice_number` (a per-business serialized counter — fine, but per-device series in DI-02 removes it from the hot path entirely) and `maintain_inventory_level` trigger throughput during large offline catch-up pushes (batched pushes in Phase 5.2 amortize this).
- **Server-enforce entitlements before selling modules** (finding SEC-02): today the module gate is client-side UX; M7 subscriptions need `business_modules` checked in RLS/RPC.
- **Device identity is about to matter** (per-device invoice series, fraud/M1 device attribution, fleet health). Introduce a registered `devices` table (id, business_id, label, platform, registered_at) now — `DeviceInfoService` already produces a label for audit logs; formalize it.

---

## 7. Testability architecture

The single biggest structural obstacle to testing is not missing tests — it's that the composition root leaks everywhere (`sl<>` in widgets/router) and the sync engine is untestable as one object. The §2–§3 changes are therefore *testability* changes:

- Registry syncers test one entity against an in-memory Drift DB + a fake remote DS each.
- `buildRouter()` with fakes makes every guard in `routePermissionGuards` a table-driven unit test.
- `AppDatabase.forTesting` already exists — build the shared harness around it (roadmap 1.6) and treat "new DAO ⇒ DAO test, new syncer ⇒ syncer test" as the review bar.
- Add one **end-to-end offline scenario test** (integration_test or a pure-Dart harness around Drift + fake remote): sell offline → restart (simulate process death) → reconnect → assert server state, invoice stability, stock convergence. This one test guards the product's core promise and would have caught findings RL-01, DI-02, and DI-03.

---

## 8. Dependency-direction summary (before → after)

| Edge today | Problem | After |
|---|---|---|
| `core/sync/sync_service.dart` → 12+ `features/*/data/datasources/*` | core depends on features; monolith | features register `EntitySyncer`s into `core/sync/engine` (dependency inverted) |
| `features/*/presentation/pages/*` → `sl<CheckoutService>()`, `sl<SyncService>()`, … | UI → service, hidden deps | pages → Bloc/Cubit → UseCase/Service; `sl` confined to `app/` + feature `di.dart` |
| `app_router.dart` (static) → `sl<>` ×30 | untestable guards | `app/router.dart` factory receiving dependencies |
| `core/config/di.dart` → everything (596 lines) | merge magnet, no ownership | `app/di.dart` composing `features/*/di.dart` modules |
| checkout pages ×2 → duplicated orchestration | two divergent money paths | one `CompleteSaleUseCase` |

---

## 9. Priorities if you only do three things

1. **Registry-based sync engine with delta pulls everywhere** (§3) — the scale ceiling, the maintainability ceiling, and a live correctness hole (wipe-guard blind spot) all resolve in one program of small PRs.
2. **Integer money + immutable invoice numbers** (§5.1, §5.4) — the two decisions that get *harder every week* and gate the BIR/fraud milestones the product roadmap is built around.
3. **Testable composition** (§7: router factory, DI modules, money-path harness) — everything else in this document is only safe to execute once this exists.
