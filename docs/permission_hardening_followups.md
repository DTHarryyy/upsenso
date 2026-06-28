# Permission & Data-Scope Hardening — Remaining Work Plan

Branch: `harden/permission-enforcement` (18 commits, 13 prod migrations).
Status: the original "overrides don't take effect" bug is fixed; server-side
enforcement was added across the app; refund approval was built; several
UI permission-mismatch bugs were fixed. This document plans everything that
remains, with enough detail to execute. It follows the project rules in
`CLAUDE.md` (UI → Cubit → UseCase → Repository → DataSource; offline-first;
reusable widgets in `lib/core/widgets/`; no hardcoded role strings; RLS is the
real enforcement; schema confirmed before queries; migrations need a rollback;
never push without permission).

---

## Recommended sequence

| # | Phase | Priority | Effort | Why this order |
|---|---|---|---|---|
| 0 | Merge + ship build | P0 | S | Unblocks real testing of everything done so far |
| 1 | Role-string sweep | P0 | M | Finishes the "granted but UI doesn't show" class of bug |
| 2 | Test harness + first tests | P1 | L | Required by CLAUDE.md; de-risks every later change |
| 3 | Server-side read scoping | P1 | L | The real data-scope security (today it's client-only) |
| 4 | Inventory tamper-proofing | P2 | L | Closes the client-supplied `source_type` gap |
| 5 | Refund-approval polish | P2 | M | Offline threshold cache + audit enrichment |
| 6 | Void approval feature | P3 | XL | Net-new feature; only if the business wants two-step voids |
| 7 | Migration ↔ prod drift | P2 | M | Hygiene; prevents future "column doesn't exist" footguns |

---

## Phase 0 — Operational (your action)

- **Merge** `harden/permission-enforcement` into `main`. The 13 migrations are
  already applied to prod, so the merge only records source. Migrations are
  idempotent (`DROP POLICY IF EXISTS` / `CREATE OR REPLACE`), so a later
  `supabase db push` won't double-apply.
- **Rebuild + deploy the app.** Every client fix this session (overrides
  resolving, nav visibility, products gating, branch/reports scoping, discount
  guard, inventory `source_type`, refund-approval UI) only takes effect on a new
  build.
- **Smoke test after rebuild:** grant a test employee `audit_logs.view` →
  confirm the menu entry appears; set an override deny on a gated write → confirm
  the API rejects it; grant a cashier `products.create` → confirm the Add button
  shows.

---

## Phase 1 — Role-string sweep (P0)

**Problem.** UI sometimes gates on hardcoded role strings (`roleName == 'cashier'`)
instead of permissions, so per-employee overrides silently do nothing. Already
fixed in `products_page.dart`, `BranchCubit`, nav (`can()` fallback). A grep for
role literals / `roleName` comparisons returns ~19 files — these must be triaged.

**Candidate files to triage** (legit vs. offender):
- Likely **offenders** (UI gating that should use permissions):
  `lib/features/home/presentation/main_navigation_page.dart` (sidebar/nav gates;
  note `_sidebarShowProducts => true` is also wrong — unconditional),
  `lib/features/procurement/data/procurement_repository.dart`,
  `lib/features/procurement/presentation/pages/po_form_page.dart`,
  `lib/features/profile/presentation/profile_page.dart`,
  `lib/core/ui/widgets/app_bottom_nav.dart` (verify — it mostly derives from
  `can()`, but the cashier/inventory *variant* logic should be double-checked).
- Likely **legitimate** (leave): `role_permission_matrix.dart`,
  `default_permission_matrix.dart` (the matrices themselves),
  `employee_role_badge.dart` / `employee_card.dart` (display only),
  `auth_bloc.dart` / `auth_remote_ds.dart` / `employees_*` (role *assignment*),
  `font_utils.dart` / `secure_storage_service.dart` / `*.g.dart` (false hits).

**Approach (per offender).**
1. Identify what capability the role string is standing in for, and map it to the
   correct `PermissionKeys` entry (action, `nav.*`, or `data.*`).
2. Replace the role check with `sl<PermissionService>().can(PermissionKeys.x)` (or
   `canAccessFeature` / `getDataScope` where it's about features/data scope).
3. For nav visibility, rely on the `can()` `nav.*`→access fallback already added.
4. Keep role strings only where they're truly about *identity/assignment*
   (assigning roles, badges), never about *access*.

**Files affected.** The offender list above + any new ones the triage finds.
**Schema/permissions.** None new — uses existing keys. If a capability has no
matching key, add it via the CLAUDE.md order (PermissionKeys → AppPermission →
AppFeature → both matrices → server `permissions` seed → PermissionService).
**Offline/sync.** None (read-only UI gating).
**Risks.** Over-restricting (a capability whose key isn't granted to a role that
needs it) — mitigate by checking `default_permission_matrix.dart` for each key
before switching, exactly as done for products. Also fix `_sidebarShowProducts`
(currently always true → shows products even without inventory/products access).
**Verification.** For each fixed surface: with an override granting the relevant
key, the affordance appears; without it, hidden; and the server still enforces
the write. Add widget/unit tests once Phase 2 lands.
**Effort.** M (a day): mechanical but needs per-file judgment + a default-matrix
check each time.

---

## Phase 2 — Test harness + first tests (P1)

**Problem.** The project has **zero tests** (`test/` does not exist). CLAUDE.md
requires coverage for permission resolution, repositories, and critical flows.
All work this session was verified via rolled-back DB impersonation only.

**Approach.**
1. **Stand up the harness:** add `flutter_test`, `bloc_test`, `mocktail` (or
   `mockito`) to `dev_dependencies`; create `test/` mirroring `lib/`.
2. **Dart unit tests (highest value first):**
   - `PermissionService.can()` precedence: override grant > override deny > role
     default > deny; module gate; `nav.*`→access fallback; owner behaviour.
   - `getDataScope()`: view_all/cross_branch → unrestricted; view_branch → branch;
     else own; override-deny narrows.
   - `DataScopingLayer.apply/effectiveBranchFilter/effectiveUserFilter`.
   - `RefundService` request/approve split (mock DAOs): atomicity, threshold,
     self-approve, money+stock effects fire once.
   - Repository methods with mocked local + remote (per CLAUDE.md).
3. **SQL/RLS tests (separate track):** the RLS + triggers can't be exercised from
   Dart. Either (a) a `supabase/tests/` pgTAP suite run in CI against a local
   Supabase, or (b) a scripted set of the rolled-back impersonation checks used
   this session (`set_config('request.jwt.claims', …); set local role
   authenticated; …; rollback`). Document the personas + expected allow/deny.
4. **CI:** `flutter test` + (optionally) the Supabase test job.

**Files affected.** `pubspec.yaml`, new `test/**`, optional `supabase/tests/**`,
CI config.
**Risks.** Some classes need light refactoring for testability (constructor
injection instead of `sl<>` inside methods) — do it surgically.
**Effort.** L (multi-day to do properly; the harness + permission-resolution
tests are the first, highest-value slice).

---

## Phase 3 — Server-side read scoping (P1)

**Problem.** A scoped user's device still **syncs all branches' rows**
(transactions/refunds/etc. are tenant-scoped on the server). `DataScopingLayer`
only filters client-side — it's defence-in-depth, not enforcement. A scoped user
could read other branches' data via the REST API.

**Approach.**
1. Decide the model: reads scoped by the user's **assigned branch(es)**
   (`employee_branches`) unless they hold `data.cross_branch_access` /
   `reports.view_all`; `own` users additionally limited to their own rows.
2. Add a SQL helper, e.g. `can_read_all_branches()` (owner bypass + the
   permission), and `my_branch_ids()` (from `employee_branches`).
3. Tighten SELECT RLS on `transactions`, `transaction_items`, `transaction_payments`,
   `refunds`, `refund_items` (and review `expenses`, `shifts`, `stock_ledger`,
   `inventory_levels`): `business_id = my_business_id() AND
   (can_read_all_branches() OR branch_id = ANY(my_branch_ids()) [AND own-row
   check for own-scope])`.
4. **Critical offline implication:** the incremental pull (`sync_service`) must
   still work when fewer rows are visible. Verify cursors/keyset paging don't
   assume all-branch rows; a scoped device simply pulls its subset. Confirm
   reports still compute from the now-narrower local cache.

**Schema.** Confirm `employee_branches` is the branch source (it is — there's no
`employees.branch_id`). No new columns expected.
**Risks (high).** A wrong SELECT policy can (a) **break the owner/manager's**
reports, or (b) **break sync** (rows silently stop arriving). Roll out one table
at a time, test with rolled-back impersonation per persona, and confirm a full
sync still lands the expected row counts.
**Rollback.** Restore the prior permissive SELECT policy per table (documented in
each migration).
**Effort.** L — careful, table-by-table, with sync verification each step.

---

## Phase 4 — Inventory tamper-proofing (P2)

**Problem.** `inventory.adjust` is enforced via the ledger gate + a guard trigger
(clients can't set `inventory_levels.quantity` directly — good). But the ledger
gate keys on **client-supplied `source_type`**; a crafted client could mislabel
an adjustment as `'sale'` to pass `pos.use`.

**Approach (pick one).**
- **A — Tie movements to their source (preferred, incremental):** in the ledger
  INSERT policy, require that `source_type='sale'` rows reference an existing
  `transactions` row (and that the movement is a decrement), `'refund'` →
  existing `refunds` row, `'purchase_order'` → existing PO/receipt. Manual
  `'adjustment'` stays gated on `inventory.adjust`. Makes spoofing require a real
  source document.
- **B — Server-computed quantities via RPC (strongest, larger):** route all
  stock movements through a `SECURITY DEFINER apply_stock_movement(...)` that
  checks the permission for the *server-determined* movement type and computes
  the delta; revoke direct `stock_ledger` INSERT. Bigger client refactor of the
  sync push.

**Risks.** Option A's cross-table checks must allow legitimate offline-synced
sales whose `transactions` row syncs in the same/earlier batch — verify ordering.
**Effort.** L (A is medium-large; B is XL).

---

## Phase 5 — Refund-approval polish (P2)

The feature works and is off by default. Refinements:
1. **Offline cache of `refund_settings`.** Today the threshold is read online at
   refund time (`fetchRefundSettings`). Cache it (Drift table + pull-sync, with
   `sync_status`) so an under-threshold refund decision works fully offline.
   Over-threshold still needs connectivity (the PIN is server-verified) — that's
   acceptable and documented.
2. **Audit-log enrichment.** Include `approval_method`/`approved_by` in the
   refund audit entry (the `audit_logs` table is append-only now).
3. **(Optional) Manager-PIN management for admins:** a screen to reset another
   employee's PIN (the RPC already supports `p_employee_id`; UI is self-only).

**Files.** New Drift table + DAO + remote pull + sync entry; `RefundService` /
audit log; optional employee-management screen.
**Effort.** M.

---

## Phase 6 — Void approval (P3, optional — net-new feature)

Voiding a **completed** sale isn't implemented (`transactions.status='voided'`
is unused; only draft/held sales are voided). `approve_void` has nothing to gate
until this exists. If wanted, mirror the refund-approval design:
1. State machine on `transactions` (`void_requested` → `voided` / rejected), or a
   dedicated `void_requests` table.
2. Server: a `BEFORE UPDATE` trigger (like the employee-suspend / refund-approval
   ones) gating the transition to `voided` on `pos.void_sale`, and to approval on
   `pos.approve_void`; inline manager-PIN reuse (`authorize_refund` generalised to
   `authorize_action`).
3. Reverse stock via the ledger (`source_type='void'` — add to the ledger gate)
   and exclude from reports (the `status != 'voided'` filter already exists).
4. UI: a void action in sales history + the existing `AppManagerPinSheet`.
**Decision required first:** does the business actually want two-step voids? Many
small businesses just use the `void_sale` permission as the gate.
**Effort.** XL.

---

## Phase 7 — Migration ↔ prod drift reconciliation (P2)

**Problem.** Prod schema diverged from older committed migrations (e.g. no
`employees.branch_id`; `get_my_permissions` was hand-edited on prod). A fresh DB
from the migration folder would not reproduce prod, and the divergence already
caused one footgun this session.

**Approach.**
1. `supabase db pull` (or diff) into a baseline migration to capture the true
   current schema; review the diff carefully.
2. Reconcile or annotate the divergent migrations; ensure a clean
   `supabase db reset` reproduces prod.
3. Add a CI check that applies all migrations to an empty DB and diffs against a
   captured prod schema snapshot.
**Risk.** Read-only/diff work is safe; do **not** apply destructive corrections to
prod without explicit approval + backup (prod is live).
**Effort.** M.

---

## Cross-cutting notes

- **Permission-model nuance (document for admins):** a user keeps the **broadest**
  scope they're granted. To restrict someone to own/branch, **deny (Block)** the
  wider keys (`reports.view_all`, `reports.view_branch`, `data.cross_branch_access`),
  not just grant `view_own`. Worth surfacing in the override editor UI (e.g. a
  hint, or auto-deny wider keys when a narrower one is set).
- **Every client change needs an app rebuild** to take effect; migrations are
  already live on prod.
- **CLAUDE.md compliance for any new feature:** follow the permission-adding order,
  keep enforcement in Bloc/UseCase + RLS (not hidden UI), offline-first with
  `id/created_at/updated_at/sync_status`, reuse `lib/core/widgets/`, log every
  `catch (e, st)` with stack trace + graceful UI, and add tests for critical paths.
- **Production safety:** confirm schema from the live DB before writing SQL; ask
  before any `supabase` CLI command; no destructive migrations without approval +
  backup; never push without explicit permission.
