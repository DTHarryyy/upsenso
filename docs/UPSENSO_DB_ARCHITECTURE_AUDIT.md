# UPSENSO — Database & Offline-Sync Architecture Audit

> **Status: AUDIT (read-only). No schema or code was modified.** Grounded in the
> LIVE prod project `dmhyfezuravbjpoxjesb` on **2026-07-04**, immediately after the
> zero-tenant reset (schema intact, 0 rows). Every number is reproducible via
> [`tool/schema_audit.sql`](../tool/schema_audit.sql); dead-column evidence comes
> from `node scratchpad/null_census.js` over `backups/reset-20260704/` (real
> pre-reset data). Migration sketches: [`scripts/db_normalization/`](../scripts/db_normalization/).
>
> **Companions (this audit consolidates + extends them):**
> [UPSENSO_DB_NORMALIZATION_PLAN.md](UPSENSO_DB_NORMALIZATION_PLAN.md),
> [delta_sync_design.md](delta_sync_design.md), [UPSENSO_RLS.md](UPSENSO_RLS.md),
> [UPSENSO_SCHEMA.md](UPSENSO_SCHEMA.md).
>
> **Guiding stance (confirmed with the owner):** prioritize normalization, but
> **respect documented offline-snapshot design** and fix only genuine debt. Every
> recommendation that could affect **sync behavior, data integrity, or app
> functionality** is flagged 🔶. `audit_logs` (incl. anomaly data) **is a
> normalization target, not an exception** — with the tamper-evident hash chain
> preserved.

---

## Executive summary

UPSENSO's backend is **not a poorly-normalized schema** — it is a **deliberately
denormalized-at-the-edges** design: a clean 3NF core (tenancy, RBAC, catalog)
plus intentional snapshot columns on transactional/ledger tables so historical
records render correctly offline even after their referents change or are deleted.
That decision is sound and documented in the table classes.

The genuine debt is a **small, well-bounded set**: a few dead/duplicate columns,
an un-normalized `audit_logs`, inconsistent sync conventions (two soft-delete
signals, two LWW column names, silent conflict discards), a **hard-delete
tombstone gap** that leaves stale rows on other devices, and a hand-rolled sync
layer (3008-line `sync_service.dart`, ~20 near-identical push methods, 15
full-pull entities) that is the main **scalability and maintainability** drag.

None of it blocks launch. All of it is fixable additively. **Overall readiness:
6.4 / 10** — production-viable for early scale, with a clear runway to "thousands
of tenants / millions of rows."

---

# Phase 1 — Complete schema inventory

| Object | Count | Notes |
|---|---:|---|
| Base tables (`public`) | **55** | full list in Phase 2 matrix |
| Views | 0 | none — all reads are table/RPC based |
| Materialized views | 0 | **no analytics/reporting layer yet** (Phase 4) |
| Triggers (non-internal) | 36 | `set_updated_at`, permission-audit, business-logic guards |
| Functions | 51 | **42 `SECURITY DEFINER`**, 9 invoker |
| Sequences | 0 | numbering uses per-business **counter tables** + `claim_*` RPCs (offline-safe, intentional) |
| Indexes | 162 | good composite coverage on hot tables; gaps on FK/RLS joins |
| Extensions | 5 | `pgcrypto`, `uuid-ossp`, `supabase_vault`, `pg_stat_statements`, `plpgsql` |
| RLS | 55 / 55 | enabled on **every** table (`role_permissions` has RLS on, **0 policies**) |

**Local mirror (offline-first):** Drift/SQLite `schemaVersion = 56`
([app_database.dart](../lib/core/database/app_database.dart)), ~37 tables / 34
DAOs. Device-only tables with no Supabase counterpart: `sync_state`,
`audit_outbox`, `fraud_candidates`, `draft_sales`/`draft_sale_items`,
`invoice_sequences`/`po_number_sequences`, `auth_context`, plus caches
(`business_modules_local`, `employee_permissions_cache`).

**Table families:** tenancy (2) · RBAC/identity (12) · catalog & templates (11) ·
lookups (categories, units) · products/recipes (3) · inventory (3) · sales &
refunds (7) · procurement (6) · expenses (1) · CRM (1) · receipt config (1) ·
numbering (2) · audit/fraud/devices (3) · ops: shifts/notifications/sync_conflicts (3).

---

# Phase 2 — Normalization audit (1NF–BCNF), 100% table coverage

**Verdict up front:** the core is **3NF-clean**. The recurring "violation" is
**intentional denormalization** — `*_name` snapshot columns and text foreign
keys on transactional/ledger tables — which is standard, correct POS/accounting
practice (a sold line must not change when the product is renamed). The audit
therefore treats those as **KEEP (documented)**, not debt.

### Coverage matrix (every table)

Legend — NF: highest normal form satisfied in practice · Verdict:
**KEEP** / **NORMALIZE** / **MERGE** / **SPLIT** / **DROP-cols**.

| Table | NF | Verdict | Note |
|---|---|---|---|
| businesses, branches | 3NF | KEEP | clean tenant roots |
| users | 3NF | KEEP | auth-identity/onboarding link (not vestigial) |
| employees | 3NF | KEEP | `role_name` denorm mirrors `role_id` for offline display (intentional) |
| employee_roles, employee_branches | 3NF/BCNF | KEEP | junction tables (correct M:N) |
| roles, permissions, modules | 3NF | KEEP | catalog; no outgoing FK by design |
| role_permissions | BCNF | KEEP | junction; ⚠️ RLS-on/**0-policies** (Phase 6) |
| user_permissions, branch_permissions | 3NF | KEEP | override grants |
| effective_permissions | 2NF* | KEEP | **computed snapshot/cache** (denorm on purpose) |
| employee_permissions | 3NF | KEEP | jsonb override blob (flexible) |
| permission_snapshot_versions | 3NF | KEEP | version bookkeeping |
| business_templates + 4 `business_template_*` | 3NF/BCNF | KEEP | blueprint catalog; template-scoped junctions |
| business_modules, business_settings | 3NF | KEEP | per-tenant config |
| categories, units | 3NF | KEEP | per-tenant lookups (unique on business+name) |
| products | 3NF | **DROP-cols** | drop nothing structural; a few optional cols unused-yet (keep) |
| product_variants | 3NF | KEEP | `stock` decimal (v46 footgun fix) |
| recipe_lines | 2NF* | KEEP | **documented no-FK snapshot** (`ingredient_name`/`unit` denorm) |
| inventory_levels | 3NF | **DROP-cols** | **drop dead `variant_id` (text dup of `product_variant_id`)** |
| stock_ledger | 3NF* | KEEP | append-only ledger; text snapshot refs (intentional) |
| stock_transfers | 3NF | KEEP | thin; unindexed FKs (Phase 4) |
| transactions | 3NF* | KEEP | `cashier_id`/name snapshot; append-only |
| transaction_items | 2NF* | KEEP | **snapshot line items** (`product_name`/`variant_name`) — correct |
| transaction_payments | BCNF | KEEP | split-tender child (good normalization) |
| refunds, refund_items | 3NF* | KEEP | snapshot + immutable |
| refund_authorizations | 3NF | **NORMALIZE** | add FK `transaction_id → transactions` (Phase 3) |
| refund_settings, procurement_settings, receipt_settings | 3NF | KEEP | per-tenant config (receipt_settings is wide but single-row) |
| suppliers | 3NF | KEEP | `contact_person`/`contact_name` slight overlap (verify) |
| purchase_orders, purchase_order_lines | 2NF* | KEEP | snapshot procurement (text ids/names, documented) |
| goods_receipts, goods_receipt_items | 2NF* | KEEP | snapshot receiving |
| expenses | 2NF* | KEEP | **deliberate denormalized snapshot** (June redesign: dropped FK cols) |
| customers | 3NF | KEEP | CRM (M5); some cols unused-yet |
| invoice_sequences, po_number_sequences | 3NF | KEEP | per-tenant counters |
| devices | 3NF | KEEP | device directory (§4c) — the normalization template |
| audit_logs | 1NF* | **NORMALIZE** | dead/legacy cols + code lookups + anomaly extraction (Phase 4 sketch) |
| fraud_flags | 3NF* | **DROP-cols** | `employee_id` dead (0/9); `evidence`/`related_ids` jsonb (extract structured signals) |
| shifts | 3NF | KEEP | cash-drawer sessions |
| notifications | 3NF | KEEP | `reference_id/type` polymorphic (CHECK-guarded) |
| sync_conflicts | 3NF | KEEP | conflict log (jsonb local/remote payloads by design) |

`*` = intentional denormalization (snapshot/cache/append-only), documented.

### Detailed normalization findings

**N-1 · `inventory_levels.variant_id` — 1NF duplicate column (DROP).**
Two columns for one concept: `product_variant_id uuid` (owns the FK +
`UNIQUE(branch_id, product_variant_id)`) and `variant_id text` (**0/3 populated**,
no FK). Rename-era leftover. → drop `variant_id`. *Benefit:* removes ambiguity +
16 bytes/row. *Migration:* Phase 1, verify the inventory remote-DS mapper writes
`product_variant_id`. *Risk:* LOW. 🔶 mapper touch.

**N-2 · `audit_logs` un-normalized (NORMALIZE — hash-safe).** Detailed in Phase 4.

**N-3 · Reference tables for repeated enums.** `action_type`/`entity_type`
(audit), `rule_code`/`severity` (fraud), status enums are bare text guarded by
CHECKs. Promoting the high-value ones to code-keyed lookups gives a single
client/server enum source and describable values. *Do NOT* promote open-ended
text (names, notes). Phase 4.

**N-4 · Intentional denormalization — KEEP & document (NOT debt):**
snapshot line items (`transaction_items`, `refund_items`), snapshot procurement
(`purchase_order*`, `goods_receipt*`), `recipe_lines` (table comment: *"No foreign
keys — recipes stay valid if the recipes module is disabled or an ingredient is
soft-deleted"*), `expenses` snapshot, `effective_permissions` cache, `stock_ledger`
projected into `inventory_levels` via `maintain_inventory_level()` trigger. These
are correct offline/historical designs; normalizing them would **break** offline
render and immutability. 🔶

**No 1NF array/multi-value violations** were found (jsonb columns —
`metadata`, `evidence`, `settings`, `permissions` — are flexible-by-design
payloads, not relational data stuffed into arrays, except the anomaly signals in
`audit_logs.metadata` / `fraud_flags.related_ids`, addressed in Phase 4).

---

# Phase 3 — Data integrity

**FK coverage is strong on the core** (all tenant `business_id`/`branch_id` on
RBAC/catalog/config tables are real FKs with explicit `ON DELETE`). Gaps:

**I-1 · Missing FK — `refund_authorizations.transaction_id`** (uuid, NOT NULL, no
FK; `transactions.id` is uuid). Clean gap, no snapshot rationale → **add FK**
(Phase 2, `NOT VALID`→`VALIDATE`). 🔶 low.

**I-2 · Intentional missing FKs (KEEP):** the procurement/stock/recipe/txn-item
text-id refs (see N-4). Enforcement is at the repository layer + snapshot columns.

**I-3 · Cascade inconsistency.** `business_id` FKs are `ON DELETE CASCADE` on most
tables but **NO ACTION** on `transactions, refunds, purchase_orders,
purchase_order_lines, stock_ledger, product_variants, audit_logs`. For the
**financial/append-only ledgers this is correct by design** (a tenant delete must
not silently erase money/stock/audit history — purges go through the explicit
`scripts/db_reset/` path). Recommendation: **document the intent**; only align the
non-ledger ones if a real hard-delete path is added.

**I-4 · Nullable tenant columns.** `branches.business_id`, `transactions.business_id`,
`transaction_items.business_id` are NULLABLE (left so in the June pass to avoid a
null-tenant sync-failure edge; RLS uses the parent join). Low urgency; tighten to
NOT NULL only once the client write-path guarantees the value. 🔶

**I-5 · Constraints present & healthy:** CHECKs on `expenses.status`,
`fraud_flags.severity/status`, `permissions.risk_level/audit_level`,
`products.type/tracking_method`, `purchase_orders.status`, `shifts.status`,
`notifications.type/severity`, `refund_items.qty/amount`; UNIQUE on all the right
natural keys (`categories(business_id,name)`, `units(business_id,name|symbol)`,
`inventory_levels(branch_id,product_variant_id)`, `ep_unique`, dedupe keys, etc.).
Immutability enforced by triggers (`stock_ledger` no-update/no-delete,
`fraud_flags_freeze_immutable`, `audit_admin_only`). This is a **mature integrity
surface.**

**I-6 · Soft-delete inconsistency (convention debt).** Two signals coexist:
`deleted_at`-only (products/variants) vs `is_deleted + deleted_at`
(suppliers/customers/PO*/recipe_lines/goods_receipts). Standardize on
`deleted_at IS NOT NULL`. 🔶 sync + query paths.

---

# Phase 4 — Performance & scalability

**Indexing:** hot delta tables are well-served — `(business_id, updated_at)`
composites exist on `products`, `product_variants`, `inventory_levels`,
`transactions`; plus targeted indexes on status/created/customer/invoice. Gaps:

**P-1 · 29 FK columns lack a supporting (leading) index** (full list in
`schema_audit.sql §7`). Most are low-traffic (permission/config), but on
larger/hot tables they cost RLS-join and parent-delete scans:
`refunds.branch_id`, `shifts.business_id`, `fraud_flags.branch_id`,
`goods_receipts.business_id`, `inventory_levels.product_variant_id`. → add
targeted indexes (Phase 5).

**P-2 · No partitioning / retention on the append-only giants.** `audit_logs`,
`stock_ledger`, `transactions`/`transaction_items` grow unbounded. At millions of
rows per tenant, plan **range partitioning by month** and an audit-log retention
window (the client already caps local audit pull to 90 days). Not urgent at
current scale; design it before the first high-volume tenant.

**P-3 · No reporting/analytics layer.** 0 views / 0 matviews. Reporting currently
computes over base tables. For long-term analytics at scale, add **materialized
views** (daily sales/inventory rollups) refreshed off-peak, or an OLAP export.
Deferred by prior decision (needs client wiring) — still the right long-term move.

**P-4 · The full-pull sync is the headline scalability risk** — see Phase 5.

**Scale verdict:** RLS-scoped-by-`business_id` + per-tenant indexing scales
horizontally to **thousands of tenants** fine. The ceilings are (a) unbounded
append-only tables without partitioning, and (b) the client sync re-downloading
whole tenant sets. Both are addressable without redesign.

---

# Phase 5 — Offline-first synchronization audit

Full code map: [sync_service.dart](../lib/core/sync/sync_service.dart) (3008
lines), `sync_status.dart`, per-DAO `upsertFromServer`, `SyncStateDao`.

**Data flow:** local write → per-row `sync_status` (0 pendingUpload / 1 update /
2 delete / 3 synced / 4 failed) → `syncAll` pushes via ~20 ordered `_syncX`
methods → Supabase → (products/variants only) server stale-guard LWW → pull
(hybrid) → `upsertFromServer` with "local-pending-wins" guard → local DB.
Triggers: startup, connectivity-restored (debounced), `Timer.periodic(60s)`.

**Change tracking:** single per-row `sync_status` outbox (the old `sync_queue`
table was already dropped). Audit uses an extra `audit_outbox` intent queue drained
into the hash chain; fraud uses a `fraud_candidates` staging queue.

### Sync findings

**S-1 · 🔶 Hybrid pull — 15 entities still full-pull every 60 s (SCALE).** Only
`products, product_variants, inventory_levels, stock_ledger, transactions,
refunds, audit_logs` use the paged delta path (`_pullIncremental`, page 500,
keyset `(updated_at,id)`). The rest (`categories, branches, expenses, employees,
suppliers, customers, fraud_flags, purchase_orders(+lines), goods_receipts(+items),
recipe_lines, devices, receipt_settings, refund_settings`) **re-download the whole
tenant set every cycle**. Readiness matrix (from `schema_audit.sql §8`):

| Delta-ready now | Has touch-trigger, needs `(business_id,updated_at)` index | Has `updated_at`, **needs trigger** (app-set = unreliable) | No `updated_at` (add, or keep full-pull) |
|---|---|---|---|
| products, product_variants, inventory_levels, transactions | suppliers, customers, purchase_orders, purchase_order_lines, recipe_lines | expenses, fraud_flags, goods_receipts, goods_receipt_items, receipt_settings, refunds | branches, categories, devices, shifts, stock_transfers, transaction_items·, refund_items· |

`·` append-only children (ride parent — fine). → Phase 5 indexes + Phase 3
triggers unlock delta for the middle two columns. This is the **single highest-ROI
scalability fix.**

**S-2 · 🔶 Hard-delete tombstone gap (CORRECTNESS).** Deletes propagate to other
devices **only** for products/variants (soft-delete `deleted_at`). Hard-deletes on
`branches, categories, expenses, employees, suppliers, PO*, recipe_lines` do a
remote `DELETE` with **no tombstone** → other devices' full-pull simply stops
seeing the row but **never removes their local mirror copy** → stale rows persist
offline. Fix: convert to soft-delete + pull-detects-`deleted_at` everywhere (the
products pattern). **Affects data integrity across devices.**

**S-3 · 🔶 Inconsistent conflict handling.** True server-side LWW stale-guard runs
**only** on products/variants (logged to `sync_conflicts` as `lww_remote_wins`).
Every other table pushes a blind `upsert` — last-writer-by-arrival wins and the
**discard is silent** (not logged), contradicting the project's "never silently
discard" rule. Fix: extend the `client_updated_at` stale-guard + conflict logging
to the other mutable tables, or accept LWW explicitly and log it.

**S-4 · Convention drift (maintainability).** Two LWW column names
(`local_updated_at` vs `client_updated_at`); two soft-delete signals (S/I-6);
`transaction_items` has no `sync_status` (rides parent — fine but asymmetric with
the server row that has `business_id`/`created_at` the local lacks).

**S-5 · Three overlapping sync-state systems** for one concept: per-row
`sync_status` (+`last_sync_attempt`+`sync_error`) **and** the `sync_state`
watermark table **and** LWW timestamp columns. Plus `audit_outbox` and
`fraud_candidates` staging queues. Each is individually justified, but together
they're the bulk of the sync bookkeeping cost.

**S-6 · Hand-rolled, scattered implementation (maintainability).** ~20
near-identical `_syncX` push methods + inline `Map` literals per table; pull
mapping re-implemented in 23 per-DAO `upsertFromServer`; only `audit`/`fraud` have
dedicated mapper files. `watchTotalPendingSyncCount` fans out to 18 per-DAO
streams. Every new table adds ~5 hand-edited touch-points.

**Simplest reliable target:** keep the per-row `sync_status` outbox + `sync_state`
watermarks (they're the right primitives); (1) push a **generic table-driven
sync** (one mapper registry + one push/pull loop parameterized per entity) to kill
the 20× duplication; (2) make **soft-delete + delta universal** (S-1/S-2); (3)
**unify LWW naming + conflict logging** (S-3/S-4). This *reduces* moving parts
while improving reliability. 🔶 (touches every synced entity — stage per-table
behind the existing flags, verify counts vs full-pull, as `delta_sync_design.md` §3).

---

# Phase 6 — Security

**Strong baseline.** RLS on all 55 tables; tenant isolation via
`current_business_id()`/`get_my_business_id()` (SECURITY DEFINER) in policies;
branch scoping (`my_branch_ids()`, `has_branch_access()`); permission enforcement
in the DB (`has_permission()`), not just UI; immutability triggers (`audit_admin_only`
SELECT-only, `stock_ledger` no-update/no-delete, `fraud_flags_freeze_immutable`);
manager-PIN + authority triggers (`enforce_role_assignment_authority`,
`protect_owner_employee`, `enforce_variant_price_authority`, `enforce_refund_approval`).

**Findings:**

**SEC-1 · `role_permissions` — RLS enabled, 0 policies.** Effectively deny-all to
authenticated roles; reads happen through SECURITY DEFINER functions. Likely
**intentional lockdown**, but confirm and document (a 0-policy table is easy to
misread as a gap). Compare with catalog tables that *do* expose a `SELECT` policy.

**SEC-2 · SECURITY DEFINER surface is broad (42 functions).** Necessary for RBAC
(they must bypass RLS to compute permissions), but each is a privilege boundary:
verify every one **pins `search_path`** and validates the caller/tenant. Memory
flags `create_employee_auth_account` within-tenant hardening as **deferred**
(requires employee-mgmt permission, not just same-tenant) — still open.

**SEC-3 · RLS layering is sound; one real duplicate (FIXED 2026-07-04).**
Correction to the first-pass read: the `*_perm_*` permission policies are
**RESTRICTIVE** and the `*_biz_isolation`/branch policies are **PERMISSIVE**, so
Postgres evaluates `(OR of permissive) AND (AND of restrictive)` — permissions are
correctly enforced on top of tenant scoping across products, product_variants,
categories, stock_ledger, suppliers, transactions, expenses, and **recipe_lines**
(its 7 policies are the intended tenant+permission layering, **not** duplicates —
leave them). The only genuine redundancy was `employee_branches` (two PERMISSIVE
generations `eb_*` and `employee_branches_*`, provably equivalent); consolidated
7→4 with zero access change on 2026-07-04. Net: the RLS design is a strength.
Minor open item — `employee_branches` writes are tenant-scoped only (no permission
layer); consider whether assigning branches should require an employee-mgmt
permission (an authz decision, not a de-dup).

**SEC-4 · Sensitive data.** `employees.manager_pin_hash` is a hash (good, 0/1
populated). No plaintext secrets in schema. `service_role` is server-only. Storage
buckets are public-read (avatars/logos/product-images) — acceptable for those asset
types; keep receipts/tax docs out of public buckets.

**Tenant isolation:** cross-ref memory `project_tenant_isolation` — the app-side
`ActiveBusinessContext` is the only businessId source; the RLS layer enforces it
server-side. No cross-tenant leak found in the policy set; the main risk is the
SEC-2 SECURITY DEFINER functions, which should each be re-reviewed for tenant
checks.

---

# Phase 7 — Production readiness

| Risk area | Level | Summary |
|---|---|---|
| **Scalability** | Medium | Full-pull sync (S-1) + unpartitioned append-only tables (P-2) are the ceilings; RLS/index model scales otherwise. |
| **Performance** | Low–Med | Good hot-path indexes; 29 unindexed FKs (P-1); no reporting MVs (P-3). |
| **Security** | Low | Mature RLS/RBAC; residual = SECURITY DEFINER review (SEC-2), `role_permissions` 0-policy confirm (SEC-1), policy de-dup (SEC-3). |
| **Data integrity** | Low–Med | Strong constraints; **hard-delete tombstone gap (S-2)** and silent conflict discards (S-3) are the real ones. |
| **Migration** | Low | Everything additive/reversible. Migration-history (`schema_migrations`) was reconciled 2026-06-28 (6 backfilled) — **re-verify it's still in sync** before any automated `db diff/push`. |
| **Operational** | Medium | Free plan = **no PITR**; only manual snapshots. Upgrade to Pro before real revenue; add error observability (Sentry). |

---

# Phase 8 — Refactoring blueprint

### Tables to DROP
**None.** Every one of the 55 tables is in active use (verified against `lib/`,
`supabase/migrations/`, and pre-reset data). The previous normalization pass
already removed the genuine orphans (`sync_queue`, `inventory_movements`,
`expense_categories`).

### Columns to DROP (three-source confirmed: dead in data + no code writer + superseded)
| Column | Evidence | Action |
|---|---|---|
| `audit_logs.employee_id` | 0/377; client never writes (mapper omits it); actor = `user_id` | DROP (Phase 1) |
| `inventory_levels.variant_id` | 0/3; text dup of `product_variant_id` (the FK/unique) | DROP (Phase 1) |
| `audit_logs.action` | legacy; only the `log_permission_change` trigger writes it | CONVERGE→`action_type`, then drop next release |
| `audit_logs.device_id` | superseded by `device_uid`+`devices`; client still sends it | RETIRE (coordinated, Phase 4) |
| `fraud_flags.employee_id` | 0/9; subject = `subject_user_id` | **Candidate — deferred** (may be populated later; documented) |

> **Explicitly NOT dropped** (0-populated only because the feature is new/unexercised —
> confirmed live via code): `transactions.customer_id`, `refunds.approved_by/approved_at/
> approval_method`, and optional cols on `products`/`product_variants`/`receipt_settings`/
> `suppliers`/`customers`. These are working optional columns, not dead ones.

### Columns to NORMALIZE
- `audit_logs.action_type`/`entity_type`, `fraud_flags.rule_code`/`severity` →
  code-keyed reference tables (Phase 4).
- Anomaly signals in `audit_logs.metadata` / `fraud_flags.related_ids` → typed
  `audit_anomaly_signals` model (Phase 4).

### New relationships
- FK `refund_authorizations.transaction_id → transactions(id)` (Phase 2).
- FK `audit_logs.action_type → audit_action_types(code)` etc. (Phase 4).

### New constraints
- Standardize soft-delete on `deleted_at`; add `set_updated_at` triggers to the 6
  delta-candidate tables lacking them; revisit NOT NULL on tenant columns.

### New indexes
- `(business_id, updated_at)` on suppliers, customers, purchase_orders,
  purchase_order_lines, recipe_lines, expenses (unlock delta).
- Supporting indexes on hot unindexed FKs (P-1).

### Tables to MERGE / SPLIT
- **None recommended.** `receipt_settings` is wide (36 cols) but a single-row-per-
  tenant config blob — splitting adds joins for no benefit. Catalog junctions are
  already correctly split.

---

# Deliverable A — Current architecture assessment

### Strengths
- Clean 3NF core; **intentional, documented denormalization** exactly where a POS
  needs it (immutable snapshot line items / ledgers).
- **Comprehensive RLS + DB-enforced RBAC** (permissions in the database, not just
  UI); mature immutability + authority triggers.
- **Offline-first primitives are sound**: per-row `sync_status` outbox, crash-safe
  idempotent watermarks, pending-wins guards, hash-chained tamper-evident audit.
- Extensible **template + module-gate** provisioning; offline-safe numbering.
- Prior normalization pass already removed real orphans and fixed the stock
  fractional footgun.

### Weaknesses
- **Sync layer is hand-rolled and duplicative** (3008-line service, ~20 push
  methods, scattered mappers) — top maintainability cost.
- **15 full-pull entities** + unindexed FKs + no partitioning = the scale ceiling.
- **Hard-delete tombstone gap** and **silent conflict discards** — cross-device
  correctness debt.
- Convention drift: two soft-delete signals, two LWW column names.
- `audit_logs` not yet normalized; no reporting/analytics layer.

### Technical debt (ranked)
1. Sync: universal soft-delete + delta + generic mapper (S-1/S-2/S-6). 🔶
2. `audit_logs` normalization + anomaly model (Phase 4). 🔶
3. Conflict-logging consistency (S-3). 🔶
4. Dead/duplicate column drops (Phase 1).
5. FK + index gaps (Phase 2/5); soft-delete/LWW unification (Phase 3).
6. RLS policy de-dup + SECURITY DEFINER review (Phase 6).
7. Migration-history reconciliation (blocks safe `db push`).

---

# Deliverable B — Fully normalized target architecture

**Shape (unchanged topology, tightened):** the ERD stays as-is — `businesses` at
the root; RBAC star (`employees`↔`roles`↔`permissions` via junctions +
override/effective tables); catalog (`products`→`product_variants`→
`inventory_levels`/`stock_ledger`); sales (`transactions`→`transaction_items`/
`transaction_payments`→`refunds`→`refund_items`); procurement chain; and the
audit/fraud/device cluster. Target deltas only:

1. **`audit_logs`** loses `employee_id`/`action`/`device_id`, references
   `audit_action_types(code)` / `audit_entity_types(code)`, and emits structured
   `audit_anomaly_signals` — while keeping each row's hash payload self-verifying
   (v3). Anomaly detection queries a **relational** model, not JSON.
2. **`inventory_levels`** single variant reference (`product_variant_id`).
3. **One tombstone convention** (`deleted_at`) and **one LWW column** name across
   all synced tables; every mutable synced table trigger-maintains `updated_at`.
4. **`refund_authorizations`** FK-linked to `transactions`.
5. Snapshot/ledger denormalization **stays** — formally documented as the offline
   design, not flagged as debt.

**Data flow (target):** local write → generic mapper → `sync_status` → **table-
driven** push → server (per-entity stale-guard + conflict log) → **universal delta
pull** (`updated_at`+soft-delete tombstones) → pending-wins upsert → local. Same
guarantees, far fewer bespoke code paths.

---

# Deliverable C — Migration plan

Sketches in [`scripts/db_normalization/`](../scripts/db_normalization/); each is
**additive → backfill → verify → drop**, carries a rollback, adds FKs
`NOT VALID`→`VALIDATE`, and **must ship its Drift schema bump + sync-mapper change
in the same release**. Re-run `tool/schema_audit.sql` before/after each phase.

| Phase | Scope | Risk | Sync/integrity impact |
|---|---|---|---|
| **1** | Drop `audit_logs.employee_id`, `inventory_levels.variant_id`; converge `action`→`action_type` | LOW | mapper touch (inventory) 🔶 |
| **2** | Add FK `refund_authorizations.transaction_id`; document ledger NO-ACTION intent | MED | none if orphan-free 🔶 |
| **3** | Unify soft-delete (`deleted_at`) + LWW naming; add `set_updated_at` triggers; tenant NOT NULL review | MED | **changes sync semantics** 🔶 |
| **4** | `audit_logs` reference tables + anomaly model; retire `device_id`; **hash v3** | HIGH | **tamper-evidence + sync** 🔶 |
| **5** | Delta-readiness indexes; hot-FK indexes; RLS policy de-dup; helper-fn consolidation; partitioning design | LOW–MED | none (perf) |

**Validation each phase:** (a) `tool/schema_audit.sql` issue count drops; (b)
`flutter analyze` + full test suite green after the Drift bump; (c) **round-trip
sync test** (write local → push → pull on a 2nd device) — the highest-risk
surface; (d) `dart run tool/diff_matrices.dart` green if permissions touched.
**Rollback:** every drop re-addable (nullable) from the file header; Phase 4 keeps
legacy rows verifier-skipped so a hash-format revert is non-destructive.
**Ordering:** client build + migration sequenced so the app never reads/writes a
column that doesn't exist yet (same rule that gated the `devices`/`hash_version`
rollout). **Prerequisite:** confirm
`supabase_migrations.schema_migrations` is still reconciled (backfilled 2026-06-28)
so `db push` is trustworthy.

---

# Deliverable D — Production readiness scores (1–10)

| Dimension | Score | Justification |
|---|:--:|---|
| **Schema normalization** | **7** | 3NF-clean core; intentional snapshots are correct; debt = a few dead/dup cols + un-normalized `audit_logs` + text/uuid id split. |
| **Scalability** | **6** | RLS+`business_id` indexing scales to many tenants; capped by 15 full-pull entities + unpartitioned append-only tables. |
| **Performance** | **6** | Strong hot-path composite indexes; 29 unindexed FKs; no reporting MVs; 60 s full re-pull. |
| **Security** | **8** | RLS on all tables, DB-enforced RBAC, immutability/authority triggers. Minus SECURITY DEFINER breadth, `role_permissions` 0-policy confirm, policy dup. |
| **Maintainability** | **5** | Hand-rolled 3008-line sync, ~20 duplicated push methods, scattered mappers, 3 overlapping state systems — the weakest area. |
| **Data integrity** | **7** | Rich constraints + immutability + hash chain; minus hard-delete tombstone gap, silent conflict discards, nullable tenant cols. |
| **Offline sync reliability** | **6** | Crash-safe idempotent watermarks + pending-wins; minus non-propagating hard deletes, inconsistent conflict logging, app-set `updated_at` on some tables. |
| **Future expansion readiness** | **6** | Template/module-gate is extensible; but each new table needs ~5 sync touch-points, and no analytics layer yet. |
| **Overall** | **6.4** | Production-viable for early scale; a small, additive, well-bounded debt list to reach "thousands of tenants / millions of rows." |

**Top 5 actions, in order:** (1) universal soft-delete + delta pull (S-1/S-2), (2)
generic table-driven sync mapper (S-6), (3) consistent conflict logging (S-3), (4)
`audit_logs` normalization + anomaly model (Phase 4), (5) Phase 1 dead/dup drops +
Phase 5 indexes. Do #1–#3 before onboarding the first high-volume tenant.

---

*Reproduce every figure with `tool/schema_audit.sql` (read-only). Nothing in this
audit has been applied to the database.*
