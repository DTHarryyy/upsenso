-- =============================================================================
-- PHASE 3 — Constraints & convention consistency   (REVIEW ONLY — DO NOT APPLY)
-- Risk: MEDIUM. Each item is additive + backfill; Drift + sync mapper must match.
-- =============================================================================

-- 1) LWW timestamp column NAME unification. Two names mean the same thing:
--    most tables use local_updated_at (client) but the server stale-guard
--    compares `client_updated_at`; refunds/fraud_flags/products/variants/
--    inventory_levels carry client_updated_at. Pick ONE server name
--    (client_updated_at) everywhere a stale-guard is wanted; document that
--    local_updated_at is the Drift-side name. This is a MAPPER change, mostly.
--    (No destructive DDL required if you standardize the push payload key.)

-- 2) SOFT-DELETE convention. Two coexist:
--      deleted_at only            → products, product_variants
--      is_deleted + deleted_at    → suppliers, customers, purchase_orders,
--                                    purchase_order_lines, recipe_lines, goods_receipts
--    Standardize on `deleted_at IS NOT NULL` as the single tombstone signal;
--    keep is_deleted as a generated/optional mirror only if the client needs it.
--    Backfill to reconcile: SET deleted_at = now() WHERE is_deleted AND deleted_at IS NULL.

-- 3) NOT NULL tightening on tenant columns that are logically required but
--    nullable (verify no null rows first). Candidates flagged by inventory:
--      branches.business_id, transactions.business_id, transaction_items.business_id
--    (currently NULLABLE — left nullable in the June pass to avoid a null-tenant
--     sync-failure edge case; RLS uses the parent join). Revisit only with the
--     client write-path guaranteeing business_id. Documented tradeoff, low urgency.

-- 4) updated_at TRIGGER coverage (delta-sync prerequisite). These have an
--    updated_at column but NO set_updated_at trigger (app-set = unreliable):
--      expenses, suppliers*, fraud_flags, goods_receipts, goods_receipt_items,
--      receipt_settings, refunds
--    Add the trigger so delta pull can trust the watermark:
--      CREATE TRIGGER trg_<t>_updated_at BEFORE UPDATE ON public.<t>
--        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
--    (*suppliers already has the trigger; listed for completeness.)

-- 5) CHECK-constraint parity with client enums. Reference-table promotion of
--    status/severity/type enums is Phase 4; until then keep the existing CHECKs
--    (expenses.status, fraud_flags.severity/status, permissions.risk_level, etc.)
--    and make sure permission_keys.dart / enums mirror them exactly.
