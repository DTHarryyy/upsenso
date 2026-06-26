-- =============================================================================
-- Phase 2 (part) — server-side permission enforcement for catalog + suppliers.
--
-- products and suppliers had RLS that only checked tenant (business_id) — any
-- authenticated member could create/edit/delete catalog items or suppliers via
-- the REST API. Add RESTRICTIVE per-WRITE-command policies that AND-in
-- has_permission(). SELECT is left to the existing permissive policy so POS and
-- reads still read the catalog.
--
-- WHY per-command (not FOR ALL): a RESTRICTIVE FOR ALL policy's USING clause
-- would also gate SELECT and break catalog reads for cashiers. Only INSERT/
-- UPDATE/DELETE are gated here.
--
-- products UPDATE: soft-delete stamps deleted_at, so an update that SETS
-- deleted_at is a delete (needs products.delete); any other update is an edit
-- (needs products.edit). products has no stock column and is never written by
-- the sale path (StockMovementService writes product_variants, not products),
-- so gating products UPDATE does not affect checkout.
--
-- DEFERRED (documented — not safe as plain RLS yet):
--   • inventory_levels / stock_ledger / product_variants.stock — written by the
--     SALE path (cashier deductions) and the receipt path, mixed onto the same
--     rows/columns as manual adjustments. Enforcing inventory.adjust needs a
--     machine-readable source/type discriminator on the remote stock_ledger
--     first; otherwise it would block cashiers' sale-driven stock sync.
--   • product_variants UPDATE (general edit) — the stock column rides the sale
--     path; can't separate a catalog edit from a sale decrement in WITH CHECK
--     (no OLD/NEW). Variant create/delete could be gated later via deleted_at.
--   • categories — created during sync, possibly inline with product creation;
--     gating by products.manage_categories risks blocking product-add for roles
--     without it. Needs client-path confirmation first.
--   • products.manage_prices — a price-change gate needs OLD/NEW comparison.
--
-- ROLLBACK: DROP POLICY each policy below. No schema change.
-- =============================================================================

-- ── products ────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS products_perm_insert ON public.products;
CREATE POLICY products_perm_insert ON public.products
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('products.create'));

DROP POLICY IF EXISTS products_perm_update ON public.products;
CREATE POLICY products_perm_update ON public.products
  AS RESTRICTIVE FOR UPDATE TO authenticated
  WITH CHECK (
    CASE WHEN deleted_at IS NOT NULL
      THEN has_permission('products.delete')
      ELSE has_permission('products.edit')
    END
  );

DROP POLICY IF EXISTS products_perm_delete ON public.products;
CREATE POLICY products_perm_delete ON public.products
  AS RESTRICTIVE FOR DELETE TO authenticated
  USING (has_permission('products.delete'));

-- ── suppliers (single suppliers.manage gate for all writes) ─────────────────
DROP POLICY IF EXISTS suppliers_perm_insert ON public.suppliers;
CREATE POLICY suppliers_perm_insert ON public.suppliers
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('suppliers.manage'));

DROP POLICY IF EXISTS suppliers_perm_update ON public.suppliers;
CREATE POLICY suppliers_perm_update ON public.suppliers
  AS RESTRICTIVE FOR UPDATE TO authenticated
  WITH CHECK (has_permission('suppliers.manage'));

DROP POLICY IF EXISTS suppliers_perm_delete ON public.suppliers;
CREATE POLICY suppliers_perm_delete ON public.suppliers
  AS RESTRICTIVE FOR DELETE TO authenticated
  USING (has_permission('suppliers.manage'));
