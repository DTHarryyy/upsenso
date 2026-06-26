-- =============================================================================
-- Close the remaining catalog / transaction-child enforcement gaps.
--
-- All RESTRICTIVE per-write-command policies AND-ed onto the existing permissive
-- tenant policies; SELECT stays open everywhere (POS + sync must read these).
-- Rollback = DROP each policy.
--
--   categories          INSERT/UPDATE/DELETE -> products.manage_categories
--     (Branch Manager + Business Owner hold both manage_categories AND
--      products.create, so inline category-creation during product add is not
--      broken; Inventory Staff/Cashier hold neither.)
--   branches            INSERT               -> settings.edit_branch
--   product_variants    INSERT               -> products.create OR products.edit
--                       UPDATE (delete only) -> products.delete when deleted_at
--                         is being set; a sale-driven stock update keeps
--                         deleted_at NULL and is unaffected. (General field edits
--                         stay open — the stock column rides the sale path and
--                         RLS can't see OLD/NEW; a manage_prices trigger is left
--                         as a follow-up to avoid offline-sync false positives.)
--   transaction_items   INSERT               -> pos.use
--   transaction_payments INSERT              -> pos.use
--     (mirror the parent sale's gate; inserted by the cashier who holds pos.use.)
-- =============================================================================

-- ── categories → products.manage_categories ─────────────────────────────────
DROP POLICY IF EXISTS categories_perm_insert ON public.categories;
CREATE POLICY categories_perm_insert ON public.categories
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('products.manage_categories'));

DROP POLICY IF EXISTS categories_perm_update ON public.categories;
CREATE POLICY categories_perm_update ON public.categories
  AS RESTRICTIVE FOR UPDATE TO authenticated
  WITH CHECK (has_permission('products.manage_categories'));

DROP POLICY IF EXISTS categories_perm_delete ON public.categories;
CREATE POLICY categories_perm_delete ON public.categories
  AS RESTRICTIVE FOR DELETE TO authenticated
  USING (has_permission('products.manage_categories'));

-- ── branches → settings.edit_branch (creation) ─────────────────────────────
DROP POLICY IF EXISTS branches_perm_insert ON public.branches;
CREATE POLICY branches_perm_insert ON public.branches
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('settings.edit_branch'));

-- ── product_variants ────────────────────────────────────────────────────────
DROP POLICY IF EXISTS product_variants_perm_insert ON public.product_variants;
CREATE POLICY product_variants_perm_insert ON public.product_variants
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('products.create') OR has_permission('products.edit'));

DROP POLICY IF EXISTS product_variants_perm_delete ON public.product_variants;
CREATE POLICY product_variants_perm_delete ON public.product_variants
  AS RESTRICTIVE FOR UPDATE TO authenticated
  WITH CHECK (deleted_at IS NULL OR has_permission('products.delete'));

-- ── transaction children → pos.use ──────────────────────────────────────────
DROP POLICY IF EXISTS transaction_items_perm_insert ON public.transaction_items;
CREATE POLICY transaction_items_perm_insert ON public.transaction_items
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('pos.use'));

DROP POLICY IF EXISTS transaction_payments_perm_insert ON public.transaction_payments;
CREATE POLICY transaction_payments_perm_insert ON public.transaction_payments
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('pos.use'));
