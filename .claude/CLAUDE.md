# CLAUDE.md — UPSENSO Project Rules (enforced every prompt)

## What This Is
UPSENSO ("Manage your business smarter") is an **offline-first Flutter POS + business-management app**. It covers point-of-sale, inventory, products/recipes, procurement, expenses, sales/refunds, employees, reporting, and an on-device AI assistant — all behind a two-layer RBAC + module-gate permission system.

- Dart package name: `pos` · Android app id: `com.ledgidy.pos` · version lives in `pubspec.yaml` (`version: x.y.z+build`).
- Targets **all six Flutter platforms** (`android`, `ios`, `web`, `macos`, `linux`, `windows`). Primary ships: Android (Play Store) and Web (Cloudflare Pages).
- ~530 Dart files. Local source of truth is **Drift/SQLite**; **Supabase** is the remote backend (Postgres + Auth + RLS + RPC).

## Tech Stack
| Concern | Choice |
|---|---|
| Framework | Flutter (Dart SDK `^3.10.7`, stable channel) |
| State management | `flutter_bloc` (Cubit + BLoC) |
| Dependency injection | `get_it` — global locator `sl` configured in `lib/core/config/di.dart` |
| Local database | `drift` over SQLite (`drift_flutter`, `sqlite3_flutter_libs`) — schema version in `app_database.dart` |
| Remote backend | `supabase_flutter` (auth, Postgres, RLS, RPC) |
| Routing | `go_router` — see `lib/app_router.dart` (guards enforce permissions) |
| Charts / PDF | `fl_chart`, `pdf`, `printing`, `print_bluetooth_thermal` |
| On-device AI | `nobodywho` (local LLM; mobile/desktop only — no web) for the AI assistant |
| Config | compile-time `--dart-define-from-file` → `lib/core/env/app_env.dart` |
| Codegen | `build_runner` + `drift_dev` (`*.g.dart`) |
| Testing | `flutter_test`, `mocktail`, `bloc_test` |

## Project Map
```
lib/
  main.dart            App entrypoint: error handlers, splash, calls bootstrap()
  bootstrap.dart       Startup order: Supabase → session recovery → DI → DB → auth → permissions
  app_bootstrap.dart   Root MaterialApp.router wiring
  app_router.dart      GoRouter routes + permission/redirect guards
  theme_data.dart      App ThemeData
  core/
    config/di.dart     get_it registrations (~100 singletons/factories)
    env/app_env.dart   Compile-time env (SUPABASE_URL, ANON_KEY, FLAVOR, …)
    database/          Drift: app_database.dart, tables/ (32), daos/ (28), connection/
    permissions/       RBAC + module gate (see Permission System section)
    sync/              connectivity_service, sync_service, sync_status
    services/          Cross-feature services: cart, checkout, refund, stock_movement,
                       invoice_number, po_number, recipe_consumption, image
    widgets/           Shared reusable widgets (App*, see Reusable Widgets section)
    const/             app_colors, app_typography, app_strings, validators, breakpoint, …
    branch/ session/ seeding/ audit/ security/ errors/ navigation/ utils/ theme/ ui/
  features/<name>/     One folder per feature, clean-architecture layered (see below)
test/                  Mirrors lib/ — mocktail + bloc_test
supabase/migrations/   ~95 timestamped SQL migrations (source of truth for the remote schema)
docs/                  Architecture, schema, RLS, permissions, access-control references
tool/diff_matrices.dart   Diffs role vs. default permission matrices (keep them in sync)
scripts/               DB backup helpers (backup_db.sh/.ps1)
```

### Feature folder layout (clean architecture)
A full feature (e.g. `lib/features/auth/`, `products/`) follows:
```
data/        datasources/ (remote_ds, local_ds), models/, repositories/ (impl)
domain/      entities/, repositories/ (interfaces), usecases/
presentation/ bloc/ or cubit/, widgets/, pages
```
Simpler features collapse this (e.g. just `pages/` + `presentation/cubit/`). Follow the layering of the **feature you are editing**; don't impose a heavier structure than its neighbors.

## Commands
Env config is injected at compile time and the `flavors/` dir is **gitignored** — you must supply `flavors/dev.json` with `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `FLAVOR`, etc. (see `app_env.dart` for the full key list).

```bash
flutter pub get                                   # install deps

# Run (always pass the dart-define file — app asserts env at startup)
flutter run --dart-define-from-file=flavors/dev.json

# Codegen — required after editing any Drift table/DAO or other generated code
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch  --delete-conflicting-outputs   # during active DB work

# Quality gates
flutter analyze                                   # lints (flutter_lints, excludes *.g.dart)
flutter test                                      # unit/bloc tests
flutter test test/core/permissions/              # scope to a dir/file

# Builds
flutter build web      --release --dart-define-from-file=flavors/prod.json
flutter build appbundle --release --dart-define-from-file=flavors/prod.json \
  --obfuscate --split-debug-info=build/debug-info/
./build.sh                                         # Cloudflare Pages web build recipe
```
CI: `.github/workflows/deploy.yml` builds a signed App Bundle and uploads to the Play Store **production** track on every push to `main`. Web deploys to Cloudflare Pages via `build.sh`.

## Code Style
- One file = one responsibility. Features in `lib/features/<name>/`. Shared code in `lib/core/`.
- Split functions over ~40 lines into smaller named functions. No monolithic files.
- Comments: human-written, explain *why* not *what*. One short line max. No docstrings.
- Never use raw `print()` — use `debugPrint` or the project logger.

## Architecture: UI → Bloc/Cubit → UseCase → Repository → DataSource
- Widgets render UI and fire events only. Zero business logic, zero Supabase calls, zero side effects in `build()`.
- **Prefer Cubit** for simple state, **BLoC** for complex event-driven flows. Never mix them in the same feature.
- UseCases are optional but preferred for complex or multi-repo flows. Repositories own all data access.
- Separate local (Drift) and remote (Supabase) data sources. Repositories combine them.
- Scope `BlocBuilder` and `BlocListener` selectors tightly — avoid full-tree rebuilds.

## Reusable Widgets
- **Always search `lib/core/widgets/` before writing any UI code.** If it exists, use it.
- Any widget used in more than one place must live in `lib/core/widgets/`. No exceptions.
- Name widgets generically so they stay reusable: `AppButton`, `SectionHeader`, `StatusBadge`, etc.
- Never hardcode colors, text styles, or spacing — use `Theme.of(context)`.
- This is how visual consistency is enforced across the app.

## Offline-First (default for every feature)
- Drift/SQLite is source of truth. Writes go local first, Supabase sync in background.
- UI shows cached data immediately and refreshes silently. Never block on a network call.
- Every synced entity must have: `id`, `created_at`, `updated_at`, `sync_status` (`pending`/`synced`/`failed`).
- Conflict resolution: Last Write Wins unless told otherwise. Log conflicts in debug. Never silently discard.
- Prefer soft deletes (`deleted_at` / `is_deleted`). Never hard-delete business data without explicit approval.
- **If a feature genuinely needs online-first**, stop and ask: *"This needs online-first — no offline fallback. Proceed?"*

## Error Handling
- No silent failures. Every `catch (e, st)` must log and do something meaningful.
- Log format: `[FeatureName] Error in methodName: $e\n$st` — stack trace is mandatory.
- User-facing errors: friendly message or error widget. Never show raw exception strings.
- Full-screen error states use Lottie from `assets/lotties/` (No Connection, Lost Connection, etc.).
- Network errors show the appropriate lottie — not just a snackbar.

## Supabase — Never Guess the Schema
- **Never assume any table, column, FK, RLS policy, index, or RPC exists.** If unsure, ask first.
- Confirm exact column names and types from the actual schema before writing any query.
- Before any `supabase` CLI command ask: *"I need to run `supabase [cmd]` — proceed?"* Wait for yes.

## Git — Never Push Without Permission
- Never `git push` unless explicitly asked. No force-push, no amending published commits.
- Show `git diff --staged` before committing. Local commits when asked — remote always needs a green light.

## Database & Migration Safety
- Every migration needs a rollback strategy before running.
- Never drop tables or columns without explicit approval. No destructive migrations automatically.
- Before any schema change confirm: schema impact → offline impact → sync impact → existing data → rollback.
- **Remote (Supabase):** schema is defined by the timestamped files in `supabase/migrations/` — they are the source of truth, never edit a table by hand without a migration. Reference docs live in `docs/UPSENSO_SCHEMA.md` and `docs/UPSENSO_RLS.md`.
- **Local (Drift):** a Drift table/DAO change means bumping `schemaVersion` in `lib/core/database/app_database.dart`, writing the matching `onUpgrade` step, then re-running `build_runner`. Keep the Drift schema and the Supabase schema reconciled — synced entities must match on both sides.

## Security
- No hardcoded secrets. Keys in env vars or secure config. Never expose `service_role` to the client.
- Validate all user input before DB writes. Never trust client-side validation alone.
- RLS and backend enforce authorization — UI-only restrictions are UX, not security.
- Financial data, inventory, employee mgmt, permissions, subscriptions → always require auth checks.

## Permission System (RBAC + Module Gate)

### Two Layers — Both Must Pass
1. **Module gate** (`BusinessModulesTable`) — toggles entire features on/off per business.
   Modules: `pos`, `inventory`, `expenses`, `employees`, `reports`, `suppliers`, `audit`.
   Disabled module = no access, regardless of role.
2. **Permission matrix** — resolves in this order:
   - Per-employee override (Supabase/Drift cache) — `true` grant / `false` deny → wins always
   - `DefaultPermissionMatrix` for the role → offline fallback
   - Deny → when nothing found

### Role Defaults
| Role | Permissions |
|---|---|
| Owner / Super Admin | All 68. Cannot be removed. |
| Branch Manager | ~32 — POS, shifts, inventory, reports, employee mgmt |
| Cashier | ~9 — POS + own shift only |
| Inventory Staff | ~9 — inventory + stock only |

Employee overrides: `null` = role default, `true` = explicit grant, `false` = explicit deny.

### Key Files — Read Before Touching Permissions
- `lib/core/permissions/permission_keys.dart` — **only** source for permission strings (`module.action`). Never use raw strings.
- `lib/core/permissions/app_permission.dart` — 68 `AppPermission` enum values
- `lib/core/permissions/app_feature.dart` — 17 `AppFeature` enum values (feature-level gating)
- `lib/core/permissions/role_permission_matrix.dart` — role → Set\<AppPermission\> + feature + profile + dashboard
- `lib/core/permissions/default_permission_matrix.dart` — same, string-keyed (offline fallback — must stay in sync)
- `lib/core/permissions/permission_service.dart` — `can(key)`, `canAccessFeature(feature)`, `guard()`
- `lib/core/database/tables/business_modules_table.dart` — module on/off state

### Adding Any New Feature — Mandatory in This Order
1. Add key(s) to `PermissionKeys` using `module.action` format.
2. Add `AppPermission` enum value(s) to `app_permission.dart`.
3. Add `AppFeature` enum value to `app_feature.dart` with `moduleCode` and `navKey`.
4. Update `role_permission_matrix.dart` — decide which roles get it by default.
5. Update `default_permission_matrix.dart` — mirror exactly (online and offline must match).
6. If new top-level module: register in `BusinessModulesTable` + module settings page.
7. Gate via `PermissionService.canAccessFeature()` in GoRouter guards **and** Bloc/UseCase logic.
8. Hidden UI elements are not access control. Permission checks belong in business logic.

> Run `dart run tool/diff_matrices.dart` to verify `role_permission_matrix.dart` and `default_permission_matrix.dart` stay in sync after touching either.

## Reference Docs (`docs/`)
Read these before deep work in the matching area — do not re-derive what's already documented:
- `UPSENSO_ARCHITECTURE.md` — overall architecture & layering
- `UPSENSO_SCHEMA.md` — Supabase/Postgres schema
- `UPSENSO_RLS.md` — Row-Level Security policies
- `UPSENSO_PERMISSIONS.md` / `UPSENSO_ACCESS_CONTROL.md` — full RBAC + module-gate model
- `delta_sync_design.md` — offline delta-sync design
- `AI_CONTEXT.md` — AI assistant context

### Product/roadmap & launch docs (read these to resume work across sessions)
- **`UPSENSO_EXECUTION_SEQUENCE.md`** — **START HERE.** The live, ordered task
  list + a "Current position / session handoff" footer with exactly what's done,
  what's pending verification, and the next action. The source of truth for "what
  do we do next."
- `UPSENSO_PRODUCT_ROADMAP.md` — milestones M1–M8 (the what & why)
- `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` — M1 deep spec (fraud + hash-chained audit)
- `UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md` — M7.1 (PHP pricing, offline limit enforcement)
- `UPSENSO_BIR_COMPLIANCE.md` — M-BIR invoice/receipt compliance + §9 pre-accreditation mode

## Testing
- New repositories → unit tests. Critical flows → integration tests. Bug fixes → regression tests.
- Write tests for: repository methods (mock both local and remote), permission resolution logic, sync status transitions, error states and edge cases.
- Must-cover areas: POS transactions, inventory updates, employee permissions, sync, subscription enforcement, migrations.
- A feature is not done until its critical paths have test coverage.

## Before Every Task — Stop and Confirm
1. Requirements fully clear? If not — **ask. Never assume or guess.**
2. Which files and modules are affected?
3. Schema confirmed from actual source (not memory)?
4. Permissions and module gate defined for this feature?
5. Offline + sync behavior planned?
6. Existing widgets/services checked before creating new ones?
7. Approach confirmed with user before writing code?

## Pre-Finish Checklist
- [ ] Single responsibility per file? No monolithic widgets or repos?
- [ ] Comments human-written, explain why (not what)?
- [ ] Reused from `lib/core/widgets/`? New shared widget extracted there?
- [ ] Schema confirmed before every Supabase query?
- [ ] Asked before any Supabase CLI command?
- [ ] No git push without explicit permission?
- [ ] Offline-first? If online-first, user warned and confirmed?
- [ ] Every `catch (e, st)` logs with stack trace and shows graceful UI?
- [ ] No hardcoded colors, text styles, or spacing?
- [ ] New feature: PermissionKeys → AppPermission → AppFeature → both matrices → module table → PermissionService?
- [ ] Permission checks in Bloc/UseCase, not just hidden UI?
- [ ] Tests written for critical paths?
