# CLAUDE.md — UPSENSO Project Rules (enforced every prompt)

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
