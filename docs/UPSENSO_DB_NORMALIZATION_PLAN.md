# UPSENSO Database Normalization Plan

> **Status: PLANNED — discovery + roadmap, no schema changes yet.** This is the
> durable plan for tightening the whole schema (both **Supabase/Postgres** and
> the local **Drift/SQLite** mirror) toward proper normalization: foreign keys
> everywhere they belong, no dead or duplicated columns, reference tables for
> repeated strings, and consistent conventions. Execute in phases; each change
> is additive-first and reversible. Companion: `UPSENSO_SCHEMA.md`,
> `UPSENSO_FRAUD_FALSE_POSITIVE_FIX_PLAN.md` (§4c already extracted the device
> label into a `devices` table — the template this plan generalizes).

## Context

Prod (`dmhyfezuravbjpoxjesb`) has **56 base tables**. Several grew wide and
picked up redundancy through schema evolution (duplicate columns from renames,
dead columns, missing FKs, repeated label strings). The audit-log incident work
already proved the pattern out: the device label was repeated on every
`audit_logs` row and is now normalized into `devices`. This plan applies the
same discipline across the schema.

**Guiding constraint — this is an offline-first app.** Every Supabase change
must be mirrored in the Drift schema (`app_database.dart` `schemaVersion` bump +
`onUpgrade` step) and reconciled through the sync mappers, or local and remote
drift apart. And prod is **LIVE** — no destructive step runs without a backup
and an additive→backfill→verify→drop sequence.

## Definition of "normalized" for this codebase

1. **Every reference is a real FK** with an explicit `ON DELETE` rule — no
   "soft" text pointers that the DB can't enforce.
2. **No dead columns** (always NULL / never read) and **no duplicate columns**
   (two columns meaning the same thing from different code eras).
3. **Repeated free-text → a reference table** keyed by id (labels, enums with
   display names). High-cardinality-repeat strings, not every string.
4. **Consistent types across tables** for the same concept (a user id is one
   type everywhere; a money column is one type everywhere).
5. **Consistent soft-delete + sync columns** (`deleted_at`, `created_at`,
   `updated_at`, `sync_status`) on every synced business entity, per CLAUDE.md.
6. **Intentional exceptions are documented**, not accidental (see the end).

## Verified findings (queried from prod 2026-07-04)

These are confirmed, not assumed — they anchor Phase 0/1:

- **`audit_logs.employee_id` is dead** — 0 of 373 rows populated. The actor is
  carried by `user_id` (238 rows). Safe to drop after confirming nothing writes
  it.
- **`audit_logs.action` vs `action_type` are a split, not a duplicate** —
  legacy DB triggers write `action` (133 rows), the app writes `action_type`
  (240 rows); they're mutually exclusive by source. Should converge to one
  column (`action_type`) with the triggers updated to populate it.
- **`audit_logs.device_id`** (the label string) is superseded by the new
  `devices` table — migrate to `device_uid`-only and drop the per-row label
  (the §4c follow-through).
- **`recipe_lines` has no foreign keys at all** — it references products /
  variants / units by id with nothing enforcing them. Real FK gap.
- **`business_templates`, `modules`, `permissions`** also have no outgoing FKs,
  but they are top-level **reference/catalog** tables — expected; leave them.
- **`users` (3 rows) vs `employees` (1 row)** are distinct concepts (auth
  identities vs business staff), not a redundancy — but the relationship and
  the `user_id`/`auth_user_id`/`employee_id` id-space needs an explicit,
  documented mapping (see Phase 2).
- **Type inconsistency to investigate**: `audit_logs.user_id` is `text` while
  most tables carry ids as `uuid`. A concept-wide type audit is Phase 1.

## Phase 0 — Discovery + guardrails (no schema change)

Before touching anything, build the evidence base so later phases are precise:

1. **Column-usage census**: for every table, `count(col)` vs `count(*)` to find
   dead columns (like `audit_logs.employee_id`) and near-dead ones.
2. **FK gap report**: list every `*_id` column whose target table exists but
   has no FK constraint. Script it from `information_schema`.
3. **Type-consistency report**: group columns by concept (`*_id`, money,
   quantity, timestamps) and flag type mismatches.
4. **Duplicate-column report**: columns on one table whose values are always
   equal or always mutually exclusive (rename leftovers).
5. **Orphan-table check**: tables with 0 rows and no code references
   (candidates for removal) vs. legitimately-empty feature tables.
6. Land these as a repeatable `tool/schema_audit.sql` so the reports can be
   re-run after each phase to prove progress.

Deliverable: a findings table (table · issue · rows affected · risk · fix
phase). Only after this do destructive steps get scheduled.

## Phase 1 — Dead + duplicate columns (low risk, high clarity)

Pattern for each (additive→backfill→verify→drop, never a bare `DROP`):

- **Dead columns** (e.g. `audit_logs.employee_id`): confirm 0 writes in code +
  0 non-null rows via Phase 0 census → drop in a migration with a rollback that
  re-adds the nullable column. Mirror by removing the Drift column (schemaVersion
  bump; Drift can't drop a column in-place on SQLite, so use its table-recreate
  migration helper).
- **Split columns** (`action` / `action_type`): (1) backfill `action_type` from
  `action` where null; (2) update the DB triggers
  (`log_permission_change` et al.) to write `action_type`; (3) once no source
  writes `action`, drop it. Keep `action` readable for one release as a safety
  net.
- **Superseded label** (`audit_logs.device_id`): the `devices` table is live;
  backfill any missing `devices` rows from distinct `(device_uid, device_id)`
  pairs, then stop writing `device_id` for new rows and drop it after the mirror
  is confirmed. **Caveat**: `device_id`/`description` are inside the hashed
  audit payload for legacy (v1) rows — dropping them changes nothing for v1
  (hash recompute is already skipped) and v2 rows must exclude them from the
  canonical payload in the SAME release (coordinate with `audit_hash.dart`, a
  hash **v3**). This is why §4c's "derived descriptions" was deferred; do it
  here deliberately.

## Phase 2 — Missing foreign keys (enforcement)

Add FKs wherever a column references an existing table without one. Process per
FK:

1. **Data hygiene first** — find and fix/repair orphan rows (`child.fk` with no
   matching parent) or the `ADD CONSTRAINT` fails. Report them from Phase 0.
2. Add the FK `NOT VALID` first (fast, locks briefly), then `VALIDATE
   CONSTRAINT` separately (no long write-lock) — standard live-Postgres
   pattern.
3. Choose `ON DELETE` deliberately: `CASCADE` for owned children (line items),
   `RESTRICT`/`SET NULL` for references (a category on a product).
4. Mirror in Drift: Drift FKs are advisory unless `PRAGMA foreign_keys=ON`;
   decide whether to enforce locally or keep them as documentation + rely on
   repository-layer integrity.

Concrete first targets: **`recipe_lines`** (product/variant/unit FKs),
`audit_logs.device_uid → devices`, and any `*_id` flagged by the Phase 0 gap
report. Tenant columns (`business_id`, `branch_id`) should all be FKs to
`businesses`/`branches` with `ON DELETE CASCADE`.

## Phase 3 — Reference tables for repeated strings

Where a free-text column repeats a small set of values with display meaning,
promote it to a lookup table keyed by code, FK the column, and keep the display
name in the lookup (not on every row). Candidates to evaluate (not assume):

- `audit_logs.action_type` / `entity_type` → an `audit_action_types` reference
  (also lets the client + server share one enum source and enables the
  server-side `CHECK`/FK the fraud plan deferred as "brittle").
- `fraud_flags.rule_code` / `severity` → reference tables (severity is already
  CHECK-constrained; a table makes it FK-enforced and describable).
- Platform / status enums that currently live as bare text.

Skip promoting genuinely open-ended text (names, notes, descriptions) — a lookup
table there is over-normalization.

## Phase 4 — Convention consistency + table cleanup

- **Standardize concept types** from the Phase 1 report (one id type, one money
  type, one timestamp convention). Each is an additive new column + backfill +
  swap + drop.
- **Soft-delete + sync columns**: ensure every synced business entity has the
  full `deleted_at` / `created_at` / `updated_at` / `sync_status` set; add the
  missing ones.
- **Remove confirmed orphan tables** (Phase 0 output) — only after grepping the
  whole codebase (Dart + SQL + migrations) for any reference, and with a
  rollback that recreates the table from its migration.
- **Reconcile the migration-history bookkeeping**: the CLI's
  `supabase_migrations.schema_migrations` table is out of sync (some migrations,
  including today's three, were applied via `db query`/dashboard, not
  `db push`). Decide on one source of truth so future `db diff`/`db push` is
  trustworthy — this blocks safe automated migration going forward.

## Safety protocol (applies to every phase)

- **Additive → backfill → verify → drop**, never a bare destructive DDL. A
  column/table is dropped only in a *later* release than the one that stopped
  using it.
- **Backup before any drop** on live prod (the schema is on the Free plan; take
  a `pg_dump` / snapshot first — no destructive op without it).
- **Drift reconciliation is part of the same change** — a Supabase migration
  that isn't mirrored in `app_database.dart` (schemaVersion + onUpgrade) and the
  sync mappers is incomplete and will desync offline clients.
- **RLS**: any new table gets policies before it's written to; any FK/`ON
  DELETE` must not let one tenant's delete cascade into another's rows.
- **Every migration carries a rollback** in its header (as today's three do),
  and each phase re-runs the Phase 0 audit to prove the issue count dropped.
- **Deploy ordering**: client build and migration must be sequenced so the app
  never reads/writes a column that doesn't exist yet (the same rule that gated
  today's `hash_version`/`devices` rollout).

## Intentional exceptions (do NOT "normalize" these)

- **`audit_logs` stays deliberately flatter than a transactional table.** Each
  row is immutable and hash-chained over its own field values; splitting fields
  into joined lookups whose values later change would make historical rows'
  meaning (and their hashes) drift. Normalize the *repeated label* (done) and
  drop *dead/duplicate* columns — but keep the row self-contained.
- **`metadata` / `evidence` jsonb columns** are flexible-by-design payloads, not
  a normalization defect. Leave them.
- **Reference/catalog tables** (`modules`, `permissions`, `business_templates`)
  legitimately have no outgoing FKs.
- **Snapshot/cache tables** (`effective_permissions`, sequence tables) trade
  normalization for read speed on purpose.

## Verification

- Phase 0 `tool/schema_audit.sql` re-run after each phase shows the target issue
  count going to zero (dead columns, FK gaps, type mismatches).
- `flutter analyze` + full test suite green after each Drift schema bump;
  migration regression tests for any backfill.
- A round-trip sync test (write local → push → pull on a second device) after
  any column/table change, since offline reconciliation is the highest-risk
  surface.
- `dart run tool/diff_matrices.dart` stays green if any permission-related table
  is touched.

## Current position / next action

- ✅ 2026-07-04: the three fraud/normalization migrations are **applied to
  prod** (`hash_version`, `devices` directory, `false_positive` status).
- ⬜ Next: **Phase 0** — build `tool/schema_audit.sql` and produce the findings
  table. Nothing destructive until that evidence exists.
- Open decision: enforce FKs in Drift (`PRAGMA foreign_keys=ON`) or keep them
  Postgres-only + repository-enforced locally.
