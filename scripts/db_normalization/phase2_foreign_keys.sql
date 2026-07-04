-- =============================================================================
-- PHASE 2 — Foreign keys & cascade consistency   (REVIEW ONLY — DO NOT APPLY)
-- Risk: MEDIUM. Fix orphans first (§11 of schema_audit.sql), add NOT VALID, then
-- VALIDATE separately. Choose ON DELETE deliberately.
-- =============================================================================

-- 1) refund_authorizations.transaction_id (uuid, NOT NULL) → transactions.id.
--    A clean gap: same type, no snapshot rationale. Verify 0 orphans first:
--      select count(*) from refund_authorizations ra
--      left join transactions t on t.id=ra.transaction_id where t.id is null;
ALTER TABLE public.refund_authorizations
  ADD CONSTRAINT ra_transaction_fk
  FOREIGN KEY (transaction_id) REFERENCES public.transactions(id)
  ON DELETE CASCADE NOT VALID;
ALTER TABLE public.refund_authorizations VALIDATE CONSTRAINT ra_transaction_fk;
-- ROLLBACK: ALTER TABLE public.refund_authorizations DROP CONSTRAINT ra_transaction_fk;

-- 2) Tenant-cascade CONSISTENCY. business_id FKs are inconsistent: most tables
--    ON DELETE CASCADE, but these are NO ACTION —
--      transactions, purchase_orders, purchase_order_lines, stock_ledger,
--      product_variants, refunds, audit_logs.
--    Decision: keep append-only/financial ledgers (audit_logs, stock_ledger,
--    transactions, refunds) as NO ACTION *by design* (a tenant delete must never
--    silently erase financial history — deletion is handled by an explicit purge
--    like scripts/db_reset/). Document that intent rather than "fixing" it.
--    Only align the non-ledger ones if a real hard-delete path needs them.

-- 3) INTENTIONAL non-FKs — DO NOT ADD (documented offline-snapshot design):
--    recipe_lines.(product_variant_id, ingredient_variant_id)  -- table comment:
--       "No foreign keys — recipes stay valid if the recipes module is disabled
--        or an ingredient is soft-deleted."
--    purchase_orders/purchase_order_lines/goods_receipts/goods_receipt_items refs,
--    stock_ledger.(variant_id,product_id,branch_id), transaction_items.variant_id,
--    refund_items.variant_id  -- all store *_name snapshots for historical render.
--    These trade referential enforcement for offline + historical stability.
