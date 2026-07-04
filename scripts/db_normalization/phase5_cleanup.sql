-- =============================================================================
-- PHASE 5 — Cleanup & scale prep   (REVIEW ONLY — DO NOT APPLY)
-- Risk: LOW–MEDIUM. Redundant objects, helper consolidation, delta-sync indexes.
-- =============================================================================

-- 1) Redundant / overlapping RLS policies (two generations from stacked migrations):
--    employee_branches has BOTH eb_{select,insert,update,delete} AND
--    employee_branches_{select,insert,delete} (7 policies). Consolidate to one set.
--    recipe_lines has generic + perm-based pairs (7 policies). Keep the perm-based,
--    drop the redundant generic ones. Verify equivalence before dropping.
--    Example: DROP POLICY employee_branches_select ON public.employee_branches;

-- 2) Redundant index: suppliers has idx_suppliers_business (business_id) alongside
--    idx_suppliers_business_active and idx_suppliers_business_name (business_id-leading).
--    If idx_suppliers_business_active is a PARTIAL index (WHERE is_active) it stays;
--    otherwise the plain idx_suppliers_business is redundant. Confirm with
--    pg_get_indexdef, then: DROP INDEX IF EXISTS idx_suppliers_business;

-- 3) Consolidate duplicate helper functions. Three return the caller's business id:
--    current_business_id(), get_my_business_id(), my_business_id(). Pick one
--    canonical (get_my_business_id) and make the others thin wrappers or drop after
--    repointing callers (RLS policies + RPCs reference them — repoint first).
--    Same for current_user_role()/current_employee() if overlapping.

-- 4) Delta-sync readiness indexes (Phase 4/5 of delta_sync_design.md). Add
--    (business_id, updated_at) to tables that have the touch-trigger but no delta
--    index, so they can move off full-pull:
CREATE INDEX IF NOT EXISTS idx_suppliers_business_updated
  ON public.suppliers (business_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_customers_business_updated
  ON public.customers (business_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_business_updated
  ON public.purchase_orders (business_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_pol_business_updated
  ON public.purchase_order_lines (business_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_recipe_lines_business_updated
  ON public.recipe_lines (business_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_expenses_business_updated
  ON public.expenses (business_id, updated_at);
-- (expenses/fraud_flags/goods_receipts also need the set_updated_at TRIGGER first
--  — see phase3 §4 — before their updated_at watermark is trustworthy.)

-- 5) Supporting indexes for the highest-traffic UNINDEXED FKs (business hard-delete
--    + RLS-join performance). Full list in schema_audit.sql §7; add the ones on
--    hot/large tables:
CREATE INDEX IF NOT EXISTS idx_refunds_branch ON public.refunds (branch_id);
CREATE INDEX IF NOT EXISTS idx_shifts_business ON public.shifts (business_id);
CREATE INDEX IF NOT EXISTS idx_fraud_flags_branch ON public.fraud_flags (branch_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_business ON public.goods_receipts (business_id);
-- (Skip the low-traffic permission/config FKs — not worth the write cost.)

-- 6) NOTE: no Postgres sequences exist; invoice/PO numbering uses per-business
--    counter tables via SECURITY DEFINER claim_* RPCs (offline-safe, intentional).
