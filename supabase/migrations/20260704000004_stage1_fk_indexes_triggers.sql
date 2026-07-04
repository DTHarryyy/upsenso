-- =============================================================================
-- Stage 1 structural hardening — ADDITIVE (normalization program, 2026-07-04)
--
-- Empty-DB moment: add the one missing clean FK, the delta-sync + hot-FK indexes,
-- and the updated_at maintenance triggers — all with zero data risk (no rows to
-- validate/backfill). Purely additive; NO client/Drift change required.
--
-- Ref: docs/UPSENSO_DB_ARCHITECTURE_AUDIT.md (Phase 2/3/4),
--      scripts/db_normalization/phase2_*.sql, phase3_*.sql, phase5_*.sql
--
-- ROLLBACK: see the per-section ROLLBACK line under each block.
-- =============================================================================

-- 1) Missing FK: refund_authorizations.transaction_id -> transactions(id).
--    A clean uuid->uuid gap (no snapshot rationale). ON DELETE left as NO ACTION
--    to match the sibling refunds.transaction_id and the ledger-preservation rule
--    (financial rows are never hard-deleted). Empty table -> validates instantly.
ALTER TABLE public.refund_authorizations
  ADD CONSTRAINT ra_transaction_fk
  FOREIGN KEY (transaction_id) REFERENCES public.transactions(id);
-- ROLLBACK: ALTER TABLE public.refund_authorizations DROP CONSTRAINT IF EXISTS ra_transaction_fk;

-- 2) Delta-sync (business_id, updated_at) indexes — prerequisite so Stage 3 can
--    move these entities off full-pull onto keyset delta pull.
CREATE INDEX IF NOT EXISTS idx_suppliers_business_updated        ON public.suppliers            (business_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_customers_business_updated        ON public.customers            (business_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_business_updated  ON public.purchase_orders      (business_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_pol_business_updated              ON public.purchase_order_lines (business_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_recipe_lines_business_updated     ON public.recipe_lines         (business_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_expenses_business_updated         ON public.expenses             (business_id, updated_at);
-- ROLLBACK: DROP INDEX IF EXISTS idx_suppliers_business_updated, idx_customers_business_updated,
--   idx_purchase_orders_business_updated, idx_pol_business_updated,
--   idx_recipe_lines_business_updated, idx_expenses_business_updated;

-- 3) Supporting indexes for hot UNINDEXED foreign keys (RLS-join + parent-delete
--    performance at scale). Low-traffic permission/config FKs are intentionally
--    skipped (not worth the write cost).
CREATE INDEX IF NOT EXISTS idx_refunds_branch        ON public.refunds        (branch_id);
CREATE INDEX IF NOT EXISTS idx_shifts_business       ON public.shifts         (business_id);
CREATE INDEX IF NOT EXISTS idx_fraud_flags_branch    ON public.fraud_flags    (branch_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_business ON public.goods_receipts (business_id);
-- ROLLBACK: DROP INDEX IF EXISTS idx_refunds_branch, idx_shifts_business,
--   idx_fraud_flags_branch, idx_goods_receipts_business;

-- 4) updated_at maintenance triggers (delta-sync prerequisite). These synced
--    tables have an updated_at column but no trigger, so updated_at was app-set
--    (unreliable for a watermark). set_updated_at() runs BEFORE UPDATE only, so
--    INSERTs keep their value — identical to the products/variants/transactions
--    pattern already in place. 🔶 makes updated_at server-authoritative on UPDATE
--    (does not affect the current full-pull path).
DROP TRIGGER IF EXISTS trg_expenses_updated_at ON public.expenses;
CREATE TRIGGER trg_expenses_updated_at BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_fraud_flags_updated_at ON public.fraud_flags;
CREATE TRIGGER trg_fraud_flags_updated_at BEFORE UPDATE ON public.fraud_flags
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_goods_receipts_updated_at ON public.goods_receipts;
CREATE TRIGGER trg_goods_receipts_updated_at BEFORE UPDATE ON public.goods_receipts
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_goods_receipt_items_updated_at ON public.goods_receipt_items;
CREATE TRIGGER trg_goods_receipt_items_updated_at BEFORE UPDATE ON public.goods_receipt_items
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_receipt_settings_updated_at ON public.receipt_settings;
CREATE TRIGGER trg_receipt_settings_updated_at BEFORE UPDATE ON public.receipt_settings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_refunds_updated_at ON public.refunds;
CREATE TRIGGER trg_refunds_updated_at BEFORE UPDATE ON public.refunds
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
-- ROLLBACK: DROP TRIGGER IF EXISTS trg_expenses_updated_at ON public.expenses;  (and the
--   other five: fraud_flags, goods_receipts, goods_receipt_items, receipt_settings, refunds)
