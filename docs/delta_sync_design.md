# Design — Incremental (Delta) Sync + Pagination

## Problem
`SyncService.pullFromServer` fetches **every** row for the business on every cycle
(`getProductsByBusiness`, `getVariantsByBusiness`, all transactions + items, full
stock ledger, etc.). At scale (millions of rows) this exhausts memory, times out,
and re-pulls unchanged data constantly. There is no watermark, no paging.

## Goal
Pull only rows changed since the last successful pull, in bounded pages, using the
**server's** clock as the ordering source (so device clock drift can't corrupt it).

---

## Hard prerequisite (Supabase schema — MUST be confirmed before implementing)
Per project rule "never guess the schema", implementation is blocked until we
confirm, for **every** synced table (`categories, products, product_variants,
inventory_levels, stock_ledger, transactions, transaction_items, expenses,
branches, businesses, employees, suppliers, purchase_orders,
purchase_order_lines, recipe_lines`):

1. An `updated_at timestamptz NOT NULL DEFAULT now()` column, **maintained by a
   trigger** on INSERT/UPDATE (app-set values are unreliable). Indexed:
   `(business_id, updated_at)`.
2. A soft-delete signal (`deleted_at timestamptz` or `is_deleted bool`) — delta
   pulls keyed on `updated_at` cannot see hard-deletes, so server deletes must
   become updates. Without this, deletions never propagate to offline devices.
3. Stable ordering tiebreak: order by `(updated_at, id)` so paging can't skip rows
   sharing a timestamp.

If any table lacks these, that table stays on full-pull until migrated.

---

## Local design

### 1. Watermark store (safe to build now — no server dependency)
New table `sync_state`:
```
entity        TEXT     -- e.g. 'products'
business_id   TEXT
last_pulled_at INTEGER -- server updated_at (epoch ms) of the last row applied
PRIMARY KEY (entity, business_id)
```
A `SyncStateDao` with `getWatermark(entity, businessId)` /
`setWatermark(entity, businessId, ts)`.

### 2. Remote data source changes
Each `getXByBusiness(businessId)` gains optional params:
```dart
Future<List<Map<String,dynamic>>> getProductsByBusiness(
  String businessId, {
  DateTime? updatedAfter,
  int limit = 500,
  DateTime? pageCursor, // last updated_at of previous page
});
```
Query shape (PostgREST):
```
.eq('business_id', businessId)
.gt('updated_at', cursor ?? updatedAfter ?? epoch0)
.order('updated_at', ascending: true)
.order('id', ascending: true)
.limit(limit)
```

### 3. Pull loop (per entity)
```
cursor = watermark(entity, business)   // null on first run → epoch 0 (full, paged)
loop:
  page = remote.get(business, updatedAfter: cursor, limit: 500)
  for row in page: dao.upsertFromServer(row)   // existing guards still apply
  if page not empty: cursor = max(row.updated_at)   // SERVER time
  until page.length < 500
setWatermark(entity, business, cursor)
```
- Watermark advances only after a page is fully applied → crash-safe (resume from
  last good cursor; at-least-once, upserts are idempotent).
- Soft-deletes arrive as normal rows with `deleted_at` set; `upsertFromServer`
  maps them to local soft-delete.

### 4. Interaction with existing offline guards
The pending-change guards added in C-4/H-4 (skip overwrite when local row is
unsynced) remain unchanged and still win over pulled data.

---

## Rollout plan (incremental, low-risk)
1. **Phase 0 (now, safe):** add `sync_state` table + `SyncStateDao` (schema bump
   + migration). Unused until Phase 2 — zero behavior change.
2. **Phase 1:** confirm/migrate server `updated_at` (+ index) and soft-delete
   columns. Backfill `updated_at = created_at` where null.
3. **Phase 2:** convert one low-risk, high-volume entity first (**stock_ledger**
   or **transactions**) to delta+paged pull behind a flag; verify counts match a
   full pull. Then roll the rest.
4. **Phase 3:** remove the full-pull path once all entities are converted.

## Risks
- Trigger-maintained `updated_at` is essential; app-set timestamps drift and break
  the watermark.
- Hard-deletes without soft-delete are invisible to delta sync → stale local rows.
- Paging without a stable `(updated_at, id)` order can skip/duplicate rows at
  timestamp boundaries.
