-- =============================================================================
-- Gate recipe_lines writes by recipes.manage (now that the permission is seeded
-- — 20260627000007). recipe_lines is the bill-of-materials; it is written only
-- by recipe management (products_remote_ds.upsertRecipeLine/deleteRecipeLine),
-- never by the sale path (recipe consumption READS the BOM and writes stock
-- movements, it does not write recipe_lines). SELECT stays open so the pull-sync
-- and sale-time consumption can still read it.
--
-- The roles that manage recipes (Business Owner, Branch Manager, Inventory Staff)
-- all hold recipes.manage; Cashier does not — so this blocks no legitimate flow.
--
-- ROLLBACK: DROP the three policies below.
-- =============================================================================

DROP POLICY IF EXISTS recipe_lines_perm_insert ON public.recipe_lines;
CREATE POLICY recipe_lines_perm_insert ON public.recipe_lines
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('recipes.manage'));

DROP POLICY IF EXISTS recipe_lines_perm_update ON public.recipe_lines;
CREATE POLICY recipe_lines_perm_update ON public.recipe_lines
  AS RESTRICTIVE FOR UPDATE TO authenticated
  WITH CHECK (has_permission('recipes.manage'));

DROP POLICY IF EXISTS recipe_lines_perm_delete ON public.recipe_lines;
CREATE POLICY recipe_lines_perm_delete ON public.recipe_lines
  AS RESTRICTIVE FOR DELETE TO authenticated
  USING (has_permission('recipes.manage'));
