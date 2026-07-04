# Stage 3 — Universal delta + soft-delete sync rollout (2026-07-04)

Client-side change (no DB migration). The server side was prepared in Stage 1
(the `(business_id, updated_at)` delta indexes + `updated_at` triggers).

## What changed, per entity
Each converted entity got three changes: (1) remote DS `getXByBusiness` → keyset
paged fetch by `(updated_at, id)` **including soft-deleted rows** (so tombstones
propagate); (2) `SyncService` pull → the shared, proven `_pullIncremental`
(watermark via `SyncStateDao`); (3) DAO `upsertFromServer` → **pending-wins guard**
(never overwrite a local row with unsynced changes — closes the silent-discard gap).

| Entity | Delta pull | Tombstone fix | Guard | Notes |
|---|:--:|:--:|:--:|---|
| suppliers | ✅ | ✅ | ✅ | had soft-delete; unit-tested |
| customers | ✅ | ✅ | ✅ | had soft-delete; unit-tested |
| purchase_orders | ✅ | ✅ | ✅ | had `is_deleted` |
| purchase_order_lines | ✅ | ✅ | ✅ | had `is_deleted` |
| goods_receipts | ✅ | ✅ | ✅ | had `is_deleted` |
| recipe_lines | ✅ | ✅ | ✅ | had `is_deleted`/`deleted_at` |
| expenses | ✅ | — | ✅ | no soft-delete column → delta-for-scale only (hard-delete didn't propagate before either — no regression) |
| goods_receipt_items | ✅ | — | ✅ | append-only child of a receipt; no independent delete |

## Left on full-pull BY DESIGN (bounded / small per tenant — delta adds risk, no scale benefit)
- `fraud_flags` — deduped incidents (small); insert-only + freeze trigger; code
  explicitly keeps full-pull to converge triage state.
- `branches`, `employees`, `business`, `receipt_settings`, `refund_settings`,
  `devices`, `categories` — small config/identity tables.

## Already delta before this stage
`products`, `product_variants`, `inventory_levels`, `stock_ledger`,
`transactions`, `refunds`, `audit_logs`.

## Net effect
Every high-volume entity now pulls only rows changed since the last watermark
(was: full tenant re-download every 60 s), and cross-device **deletes now
propagate** for the soft-delete entities (previously stranded — deleted rows
lingered on other devices). Silent-discard on pull is closed via the guard.

## Verification
- `flutter analyze` clean; full suite **206 green** (incl. new suppliers +
  customers delta/tombstone/guard unit tests).
- **Live 2-device round-trip pending** (owner action) — see the QA script.
