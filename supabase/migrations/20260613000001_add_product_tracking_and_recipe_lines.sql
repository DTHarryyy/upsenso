-- =============================================================================
-- UPSENSO — Sync support for ingredient/recipe products
-- =============================================================================
-- Two gaps blocked ingredient & recipe products from surviving a Supabase pull:
--   1. products had no `type` / `tracking_method` columns, so the app could not
--      round-trip whether a product is an ingredient or a recipe-tracked item.
--   2. recipe_lines (the bill-of-materials) had no table at all, so recipes were
--      device-local only.
-- This migration is purely additive + idempotent (safe to re-run). Rollback:
-- drop the two columns and the recipe_lines table.
-- =============================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. products: classification columns
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.products
  -- 'product' (sellable) | 'ingredient' (consumed by recipes, never sold).
  ADD COLUMN IF NOT EXISTS type            text NOT NULL DEFAULT 'product',
  -- 'product_stock' (own stock) | 'recipe' (deduct ingredients) | 'service'.
  ADD COLUMN IF NOT EXISTS tracking_method text NOT NULL DEFAULT 'product_stock';

ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_type_check,
  DROP CONSTRAINT IF EXISTS products_tracking_method_check;

ALTER TABLE public.products
  ADD CONSTRAINT products_type_check
    CHECK (type IN ('product', 'ingredient')),
  ADD CONSTRAINT products_tracking_method_check
    CHECK (tracking_method IN ('product_stock', 'recipe', 'service'));

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. recipe_lines: bill-of-materials for recipe-tracked variants
-- ─────────────────────────────────────────────────────────────────────────────
-- Mirrors lib/core/database/tables/recipe_lines_table.dart. No FKs by design —
-- recipes stay valid if an ingredient is soft-deleted or the module is off;
-- ingredient_name/unit are denormalized for historical rendering.

CREATE TABLE IF NOT EXISTS public.recipe_lines (
  id                    text PRIMARY KEY,
  business_id           uuid        NOT NULL,
  product_variant_id    text        NOT NULL,
  ingredient_variant_id text        NOT NULL,
  ingredient_name       text        NOT NULL,
  quantity              numeric     NOT NULL DEFAULT 0,
  unit                  text,
  is_deleted            boolean     NOT NULL DEFAULT false,
  deleted_at            timestamptz,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_recipe_lines_business
  ON public.recipe_lines (business_id)
  WHERE is_deleted = false;

CREATE INDEX IF NOT EXISTS idx_recipe_lines_variant
  ON public.recipe_lines (product_variant_id)
  WHERE is_deleted = false;

-- updated_at auto-maintenance (same trigger fn used across the schema).
DROP TRIGGER IF EXISTS trg_recipe_lines_updated_at ON public.recipe_lines;
CREATE TRIGGER trg_recipe_lines_updated_at
  BEFORE UPDATE ON public.recipe_lines
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. RLS — business isolation (recipes are business config; app gates by module)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.recipe_lines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS recipe_lines_select ON public.recipe_lines;
DROP POLICY IF EXISTS recipe_lines_insert ON public.recipe_lines;
DROP POLICY IF EXISTS recipe_lines_update ON public.recipe_lines;
DROP POLICY IF EXISTS recipe_lines_delete ON public.recipe_lines;

CREATE POLICY recipe_lines_select ON public.recipe_lines
  FOR SELECT TO authenticated
  USING (business_id = my_business_id());

CREATE POLICY recipe_lines_insert ON public.recipe_lines
  FOR INSERT TO authenticated
  WITH CHECK (business_id = my_business_id());

CREATE POLICY recipe_lines_update ON public.recipe_lines
  FOR UPDATE TO authenticated
  USING (business_id = my_business_id())
  WITH CHECK (business_id = my_business_id());

-- Recipe lines are replaceable BOM rows (rebuilt on edit), so a hard remote
-- delete on pending-delete is fine — mirrors purchase_order_lines.
CREATE POLICY recipe_lines_delete ON public.recipe_lines
  FOR DELETE TO authenticated
  USING (business_id = my_business_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Grants
-- ─────────────────────────────────────────────────────────────────────────────

REVOKE ALL ON public.recipe_lines FROM anon, public;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.recipe_lines TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Reload PostgREST schema cache
-- ─────────────────────────────────────────────────────────────────────────────

SELECT pg_notify('pgrst', 'reload schema');

COMMIT;
